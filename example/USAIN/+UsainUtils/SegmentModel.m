classdef SegmentModel < matlab.mixin.SetGet & logging.Config
    % SEGMENTMODEL Flange segment model as used in academic papers
    %   This model can be seen as a submodel to the parent FlangeModel. It is
    %   used in certain design condition evaluations.
    %

    properties
        Mdl                 % Parent FlangeModel
        ReactDist UsainUtils.ReactionDistance

        resilFlanges
        resilClampedPkg
        resilBolt
        loadFactor

        distRim             % Flange rim distance ("a" in literature), [m]
        distForce           % Flange force application width ("b" in literature), [m]
        distBolt            % Center distance between bolts, ("c" in literature), [m]
        distBoltAtShell     % Segment width, at middle of shell/nose, ("c*" in literature), [m]
    end

    methods

        function Obj = SegmentModel(varargin)
            if nargin
                Obj = assign_varargin_2_classprop(Obj, varargin{:});
            end
        end

        %%%%% == SEGMENT MODEL SETUP == %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function setup_segment_model(Obj)

            % Shortcuts
            width  = Obj.Mdl.Space.width;
            nBolts = Obj.Mdl.Space.nBolts;

            % Compute load factor, i.e. the fraction of the applied load carried
            % by the flange
            Obj.loadFactor = Obj.calc_load_factor();

            % Compute geometrical parameters
            tNose = min(Obj.Mdl.Inputs.thicknNoseUp, Obj.Mdl.Inputs.thicknNoseLo);
            bcd = Obj.Mdl.diameterBoltCircle;
            diamMidNeck = Obj.Mdl.diameterOutNeck - tNose;
            Obj.distRim = Obj.calc_inner_width(Obj.Mdl.diamOutFlange, bcd, width);
            Obj.distForce = Obj.calc_outer_width(Obj.Mdl.flangeType, Obj.Mdl.diameterOutNeck, bcd, ...
                Obj.Mdl.Inputs.thicknNoseUp, Obj.Mdl.Inputs.thicknNoseLo);
            Obj.distBolt = Obj.calc_segment_width(bcd, nBolts);
            Obj.distBoltAtShell = Obj.calc_segment_width(diamMidNeck, nBolts);

            if isscalar(Obj.distForce)
                % Ensure distForce to have equal size as distRim etc.
                Obj.distForce = Obj.distForce * ones(Obj.Mdl.Space.nPoints, 1);
            end

            Obj.ReactDist = UsainUtils.ReactionDistance(Obj.distRim, Obj.distForce, Obj.Mdl.Space.thickness);
        end

        %%%%% == SEGMENT FORCE COMPUTATIONS == %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function fApplied = calc_segment_force(Obj, mxy, fz, iCalc)
            % Returns force on flange segment model
            % A globally applied bending moment is converted to a force acting on the nose of the segment
            % model. This force is combined with the normal force from dead weight.
            %
            % mxy:   [double, M*N] Bending moment(s).
            %        For ULS: 1*N for N load sets
            %        For FLS: M*N for M bins and where N=2 (min/max range)
            % fz:    [double, 1*1] Normal force from dead weight. Value will be added to force from bending
            %        moment, hence provide negative value to model compressive normal force.
            % iCalc: [double, K*1] Index mask for design points to include. If not input. all design points
            %        are considered
            %
            % fApplied: [double, K*M*N] Applied force on segment model, for all K points in design space
            %

            if nargin < 4
                iCalc = 1:Obj.Mdl.Space.nPoints;
            end

            nBolts = Obj.Mdl.Space.nBolts(iCalc);
            tNose = min(Obj.Mdl.Inputs.thicknNoseUp, Obj.Mdl.Inputs.thicknNoseLo);
            dMean = Obj.Mdl.diameterOutNeck - tNose;

            % Compute force applied on flange segment and do some magic with matrix sizes/operations (for working with
            % fatigue load spectra specifically):
            % - Prepend a dimension to moment `mxy`. For FLS, `mxy` has size N-by-M. This becomes 1-by-N-by-M.
            % - Use `bsxfun(@rdivide, ...` to compute `moment / diameter` for all K design point and all `N-by-M`
            %   moments. Hence, this gives a K-by-N-by-M array.
            % NOTE: For ULS, where `mxy` is a scalar, all this magic is not needed but does not affect results either
            forceFull = 4 .* bsxfun(@rdivide, reshape(mxy, [1, size(mxy)]), dMean(iCalc)) + fz;
            fApplied = forceFull ./ nBolts;
        end

        %%%%% == BOLT LOAD FACTOR COMPUTATIONS == %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function loadFactor = calc_load_factor(Obj)
            % Returns load factor; assigns resil* properties

            % Compute fastener resilience; note that this is done differently
            % for studs and bolts
            isStud = strcmpi(Obj.Mdl.Bolt.type, 'stud');
            Obj.resilBolt = Obj.calc_resilience_bolt();
            resStud = Obj.calc_resilience_stud();
            Obj.resilBolt(isStud) = resStud(isStud);

            % Compute resilience of flanges
            Obj.resilFlanges  = Obj.calc_resilience_flanges();

            % Compute resilience of 'clamped parts', i.e. parts compressed by
            % pretension
            resilWashers  = Obj.calc_resilience_washers();
            resilExtender = Obj.calc_resilience_extender();
            Obj.resilClampedPkg = Obj.resilFlanges + resilWashers + resilExtender;

            % Compute load factor
            loadFactor = Obj.resilFlanges ./ (Obj.resilClampedPkg + Obj.resilBolt);
        end

        function resil = calc_resilience_bolt(Obj)
            % Computes resilience (1/stiffness) of hex bolt
            % The (elastic) resilience of the bolt is a summation of the various cylindrical elements of
            % different lengths and areas in the bolt assembly, according to section 5.1, eq.3 in
            % VDI2230:2003.
            % The different bolt parts considered are:
            %    - Bolt head
            %    - Bolt shaft (bolt part without thread)
            %    - Bolt thread (gripped thread)
            %    - Nut or tapped hole (combination of minor diameter and nut thread regions)

            % Compute resilience of bolt head
            lenBoltHead = 0.5 * Obj.Mdl.Bolt.diam;
            areaBolt    = (pi / 4) * Obj.Mdl.Bolt.diam.^2;
            resBoltHead = lenBoltHead ./ (Obj.Mdl.Inputs.E_BOLT * areaBolt);

            % Compute resilience of bolt shaft. If input IGNORE_BOLT_EXTENDER dictates that the extender is to
            % be ignored for the resilience calculations, also substract the bolt extender length from the
            % bolt shaft length.
            lenExtForShaft = Obj.Mdl.Inputs.IGNORE_BOLT_EXTENDER * Obj.Mdl.Extr.len;
            lenShaft = (Obj.Mdl.Bolt.len - Obj.Mdl.Bolt.lenThread) - lenExtForShaft;
            resShaft = lenShaft ./ (Obj.Mdl.Inputs.E_BOLT * areaBolt);

            % Compute resilience of gripped threads. Handle input IGNORE_BOLT_EXTENDER in the same was as for
            % the shaft length
            lenExtForThread = ~Obj.Mdl.Inputs.IGNORE_BOLT_EXTENDER * Obj.Mdl.Extr.len;
            thickn = Obj.Mdl.Space.thickness;
            lenThread  = (2 * (thickn + Obj.Mdl.Wash.len) + lenExtForThread) - lenShaft;
            areaThread = (pi / 4) * Obj.Mdl.Bolt.minorDiameter.^2;
            resThread  = lenThread ./ (Obj.Mdl.Inputs.E_BOLT * areaThread);

            % Compute resilience of load carrying part of the nut (assuming first 40% of nut's length to be
            % load carrying)
            lenNut = 0.4 * Obj.Mdl.Bolt.diam;
            resNut = lenNut ./ (Obj.Mdl.Inputs.E_BOLT * areaBolt);

            % Compute resilience of bolt thread gripped by nut (assuming 50% of the bolt thread to be gripped
            % properly)
            lenNutThread = 0.5 * Obj.Mdl.Bolt.diam;
            resNutThread = lenNutThread ./ (Obj.Mdl.Inputs.E_BOLT * areaThread);

            % Sum component resiliences and return total axial resilience
            resil = resBoltHead + resShaft + resThread + resNut + resNutThread;
        end

        function resil = calc_resilience_stud(Obj)
            % Computes resilience (1/stiffness) of stud bolt
            % Similar to CALC_RESILIENCE_BOLT, but for studs. See SGRE Design Brief for Flanges for underlying
            % formulas and more info

            % Compute resilience of bolt shank. If input IGNORE_BOLT_EXTENDER dictates that the extender is to
            % be ignored for the resilience calculations, also subtract the bolt extender length from the
            % bolt shank length.
            % NOTE: Shank diameter computed according to ISO724 (pitch diameter), following ZPS 1037252, Table
            % D1.1.-3
            lenExtForShank = Obj.Mdl.Inputs.IGNORE_BOLT_EXTENDER * Obj.Mdl.Extr.len;
            eModBolt = Obj.Mdl.Inputs.E_BOLT;
            areaBolt = (pi / 4) * Obj.Mdl.Bolt.pitchDiameter.^2;
            lenShank = (Obj.Mdl.Bolt.len - 2 * Obj.Mdl.Bolt.lenThread) - lenExtForShank;
            resShank = UsainUtils.SegmentModel.calc_resilience(lenShank, areaBolt, eModBolt);

            % Compute resilience of gripped threads. Handle input IGNORE_BOLT_EXTENDER in the same was as for
            % the shaft length
            lenExtForThread = ~Obj.Mdl.Inputs.IGNORE_BOLT_EXTENDER * Obj.Mdl.Extr.len;
            thickn = Obj.Mdl.Space.thickness;
            lenThread  = (2 * (thickn + Obj.Mdl.Wash.len) + lenExtForThread) - lenShank;
            areaThread = (pi / 4) * Obj.Mdl.Bolt.minorDiameter.^2;
            resThread = UsainUtils.SegmentModel.calc_resilience(lenThread, areaThread, eModBolt);

            % Compute resilience of load carrying part of the nut (assuming first 40% of nut's length to be
            % load carrying)
            lenNut = 0.4 * Obj.Mdl.Bolt.diam;
            areaBoltNominal = (pi / 4) * Obj.Mdl.Bolt.diam.^2;
            resNut = UsainUtils.SegmentModel.calc_resilience(lenNut, areaBoltNominal, eModBolt);

            % Compute resilience of bolt thread gripped by nut (assuming 50% of the bolt thread to be gripped
            % properly)
            lenNutThread = 0.5 * Obj.Mdl.Bolt.diam;
            resNutThread = UsainUtils.SegmentModel.calc_resilience(lenNutThread, areaThread, eModBolt);

            % Sum component resiliences and return total axial resilience
            resil = resShank + resThread + 2 * (resNut + resNutThread);
        end

        function resil = calc_resilience_washers(Obj)
            % CALC_RESILIENCE_WASHERS Returns inverse axial stiffness of washers
            % The combined resilience of both washers is returned.
            % The resilience is computed according to eq 53 in Petersen's "Stahlbau"

            % Compute resilience of single washer
            areaWash = (pi / 4) * (Obj.Mdl.Wash.diamOut.^2 - Obj.Mdl.Wash.diamIn.^2);

            % Return resilience of both washers
            resil = 2 * (Obj.Mdl.Wash.len ./ (Obj.Mdl.Inputs.E_BOLT * areaWash));

            % Do not compute if no washer is present
            resil(Obj.Mdl.Wash.len <= 1e-6) = 0;
        end

        function resil = calc_resilience_extender(Obj)
            % Computes resilience (1/stiffness) of bolt extender
            % The resilience is computed according to eq 53 in Petersen's "Stahlbau". Zero resilience is
            % returned for designs without bolt extender or when input IGNORE_BOLT_EXTENDER is true.

            if abs(Obj.Mdl.Extr.len) < 1e-6
                resil = 0;
            else
                areaExtr = (pi / 4) * (Obj.Mdl.Extr.diamOut.^2 - Obj.Mdl.Extr.diamIn.^2);
                resil = (~Obj.Mdl.Inputs.IGNORE_BOLT_EXTENDER * Obj.Mdl.Extr.len) ./ ...
                    (Obj.Mdl.Inputs.E_FLANGE * areaExtr);
            end
        end

        function resil = calc_resilience_flanges(Obj)
            % CALC_FLANGES_AXIAL_RESILIENCE Returns inverse axial stiffness of flanges
            % The resilience of both flanges is returned. It is computed according to the assumed cylindrical
            % stress sleeve originally proposed by Petersen in Stahlbau (eq 63).
            %
            % Note that the stress cone computation described in VDI2230 is considered to be non-conservative,
            % especially when combined with the bolt force model from Schmidt-Neuper.
            %
            %

            thickn = Obj.Mdl.Space.thickness;

            % Calculate resilience of flange
            diamContact = usain.fastener.calc_contact_diameter(Obj.Mdl.Nut.diam, Obj.Mdl.Wash.diamOut, ...
                Obj.Mdl.Wash.len);
            areaSleeve = (pi / 4) * ((diamContact + 0.2 * thickn).^2 - Obj.Mdl.Inputs.diamBoltHole.^2);
            resil = (2 * thickn) ./ (Obj.Mdl.Inputs.E_FLANGE * areaSleeve);
        end

        function beta = calc_bending_resilience_bolt(Obj)

            % Compute resilience of bolt head
            eModBolt = Obj.Mdl.Inputs.E_BOLT;
            lenBoltHead = 0.5 * Obj.Mdl.Bolt.diam;
            inertiaBolt = (pi / 64) * Obj.Mdl.Bolt.diam.^4;
            resBoltHead = UsainUtils.SegmentModel.calc_resilience(lenBoltHead, inertiaBolt, eModBolt);

            % Compute resilience of bolt shaft. If input IGNORE_BOLT_EXTENDER dictates that the extender is to
            % be ignored for the resilience calculations, also substract the bolt extender length from the
            % bolt shaft length.
            lenExtForShank = Obj.Mdl.Inputs.IGNORE_BOLT_EXTENDER * Obj.Mdl.Extr.len;
            lenShank = (Obj.Mdl.Bolt.len - Obj.Mdl.Bolt.lenThread) - lenExtForShank;
            resShank = UsainUtils.SegmentModel.calc_resilience(lenShank, inertiaBolt, eModBolt);

            % Compute resilience of gripped threads. Handle input IGNORE_BOLT_EXTENDER in the same was as for
            % the shaft length
            lenExtForThread = ~Obj.Mdl.Inputs.IGNORE_BOLT_EXTENDER * Obj.Mdl.Extr.len;
            thickn = Obj.Mdl.Space.thickness;
            lenThread  = (2 * (thickn + Obj.Mdl.Wash.len) + lenExtForThread) - lenShank;
            inertiaThread = (pi / 64) * Obj.Mdl.Bolt.minorDiameter.^4;
            resThread = UsainUtils.SegmentModel.calc_resilience(lenThread, inertiaThread, eModBolt);

            % Compute resilience of load carrying part of the nut (assuming first 40% of nut's length to be
            % load carrying)
            lenNut = 0.4 * Obj.Mdl.Bolt.diam;
            resNut = UsainUtils.SegmentModel.calc_resilience(lenNut, inertiaBolt, eModBolt);

            % Compute resilience of bolt thread gripped by nut (assuming 50% of the bolt thread to be gripped
            % properly)
            lenNutThread = 0.5 * Obj.Mdl.Bolt.diam;
            resNutThread = UsainUtils.SegmentModel.calc_resilience(lenNutThread, inertiaThread, eModBolt);

            % Sum resiliences of individual parts
            beta = resBoltHead + resShank + resThread + resNut + resNutThread;
        end

        function beta = calc_bending_resilience_stud(Obj)

            % Compute bending resilience of the shank. If input IGNORE_BOLT_EXTENDER dictates that the
            % extender is to be ignored for the resilience calculations, also substract the bolt extender
            % length from the bolt shank length.
            % NOTE: Shank diameter computed according to ISO724 (pitch diameter), following ZPS 1037252, Table
            % D1.1.-3
            lenExtForShank = Obj.Mdl.Inputs.IGNORE_BOLT_EXTENDER * Obj.Mdl.Extr.len;
            eModBolt = Obj.Mdl.Inputs.E_BOLT;
            inertiaShank = (pi / 64) * Obj.Mdl.Bolt.pitchDiameter.^4;
            lenShank = (Obj.Mdl.Bolt.len - 2 * Obj.Mdl.Bolt.lenThread) - lenExtForShank;
            resShank = UsainUtils.SegmentModel.calc_resilience(lenShank, inertiaShank, eModBolt);

            % Compute resilience of gripped threads. Handle input IGNORE_BOLT_EXTENDER in the same was as for
            % the shaft length
            lenExtForThread = ~Obj.Mdl.Inputs.IGNORE_BOLT_EXTENDER * Obj.Mdl.Extr.len;
            thickn = Obj.Mdl.Space.thickness;
            lenThread  = (2 * (thickn + Obj.Mdl.Wash.len) + lenExtForThread) - lenShank;
            inertiaThread = (pi / 64) * Obj.Mdl.Bolt.minorDiameter.^4;
            resThread = UsainUtils.SegmentModel.calc_resilience(lenThread, inertiaThread, eModBolt);

            % Compute resilience of load carrying part of the nut (assuming first 40% of nut's length to be
            % load carrying)
            lenNut = 0.4 * Obj.Mdl.Bolt.diam;
            resNut = UsainUtils.SegmentModel.calc_resilience(lenNut, inertiaShank, eModBolt);

            % Compute resilience of bolt thread gripped by nut (assuming 50% of the bolt thread to be gripped
            % properly)
            lenNutThread = 0.5 * Obj.Mdl.Bolt.diam;
            resNutThread = UsainUtils.SegmentModel.calc_resilience(lenNutThread, inertiaThread, eModBolt);

            % Sum resiliences of individual parts
            beta = resShank + resThread + 2 * (resNut + resNutThread);
        end

        function beta = calc_bending_resilience_fastener(Obj)
            % General method for calculating the bending resilience of studs and bolts

            % Generally, studs are used so compute bending resilience for studs
            beta = Obj.calc_bending_resilience_stud();

            % If bolts are present in the design space, override the respective indices
            isHexBolt = strcmpi(Obj.Mdl.Bolt.type, 'hex');
            if any(isHexBolt)
                betaBolt = Obj.calc_bending_resilience_bolt();
                beta(isHexBolt) = betaBolt(isHexBolt);
            end

            % For debugging: A simplification that shows to give reasonably similar results:
            % beta = 192 * Obj.Mdl.Space.thickness ./ (Obj.Mdl.Inputs.E_BOLT .* pi .* Obj.Mdl.Bolt.diam.^4);
        end

    end

    methods (Static)

        function Obj = setup_obj(Mdl)
            Obj = UsainUtils.SegmentModel('Mdl', Mdl);
            Obj.setup_segment_model();
        end

        function a = calc_inner_width(diam, bcd, width)
            % Computes inner width "a", distance bolt axis to flange inner edge
            %
            % INPUT
            %   diam:  [double] Flange outer diameter
            %   bcd:   [double] Bolt circle diameter
            %   width: [double] Flange width

            diamIn = diam - 2 .* width;
            a = (bcd - diamIn) ./ 2;
        end

        function b = calc_outer_width(FlangeType, diameterOutNeck, diameterBoltCircle, neckThicknessUp, neckThicknessLo)
            % Computes outer width "b", distance bolt axis to shell mid
            % See also: usain.model.SegmentModel.calc_parameter_b()

            if FlangeType == usain.inputs.FlangeType.L
                minNeckThickness = min(neckThicknessUp, neckThicknessLo);
                b = (diameterOutNeck - minNeckThickness - diameterBoltCircle) ./ 2;
            elseif FlangeType == usain.inputs.FlangeType.T
                b = (diameterOutNeck - diameterBoltCircle - neckThicknessUp) ./ 2;
            end
        end

        function c = calc_segment_width(diam, nBolts)
            % Computes segment width "c"
            % The segment width, or influence width, is usually denoted with "c"
            % or a variant on that (eg. c', c*). Just "c" would represent the
            % distance between bolts (= segment width at the BCD)
            %
            % INPUT
            %   diam:    [double] Diameter at which segment width is to be computed
            %   nBolts:  [double] Number of bolts
            %

            c = pi * diam ./ nBolts;
        end

        function resil = calc_resilience(len, areaOrInertia, eMod)
            % Returns resilience (inverse stiffness) of fastener component
            % If the area is provided, the axial resilience is computed. If the inertia is provided, the
            % bending resilience is computed.
            resil = len ./ (areaOrInertia .* eMod);
        end

    end
end
