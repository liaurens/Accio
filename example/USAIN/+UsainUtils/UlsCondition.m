classdef UlsCondition < UsainUtils.ICondition
    % Base class for ULS conditions
    %
    % This class takes care of common flange ULS condition calculations, like determining design tensile
    % force, design yield strength, etc.

    properties
        % N = Number of design points
        % M = Number of load sets

        fz double  % [1*1] Normal force, negative = compressive
        mxy double  % [1*M] Bending moment, negative = compressive

        fDesign double   % [N*M] Tensile force acting on flange, incl. additional SCF

        yieldStrengthDes double  % [N*M] Design value for yield strength of flange material
    end

    methods

        function Obj = UlsCondition(varargin)
            Obj@UsainUtils.ICondition(varargin{:});
        end

        function force = calc_design_segment_force(Obj)
            % Computes design value of flange segment force for extreme load cases.
            % The max. ULS load per input load set is used for determining the segment force.
            % If applicable, an additional SCF is applied as well.
            % NOTE: SCF applied for ULS, as this can be interpreted as a load intensification (e.g. due to
            % disturbances near a flange, like jacket legs or doorframes)

            fSegment = Obj.Mdl.Segment.calc_segment_force(Obj.mxy, Obj.fz);
            fSegment = Obj.squeeze_dims(fSegment);
            force = Obj.Mdl.Inputs.ADDITIONAL_SCF_ULS * fSegment;
        end

        function fyd = calc_design_yield_strength(Obj)
            % Returns design value of flange material yield strength

            switch upper(Obj.Mdl.Inputs.countryCode)
                case 'ROW'
                    fyd = Obj.calc_design_yield_strength_row();
                case 'JPN'
                    fyd = Obj.calc_design_yield_strength_jpn();
                otherwise
                    Obj.error('Implementation error: Invalid country code.');
            end
        end

        function fyd = calc_design_yield_strength_row(Obj)
            % Returns design value of flange material yield strength for non-Japan designs

            psf = Obj.calc_strength_psf(Obj.Mdl.Inputs.PSF_CMPCLASS2_ULS * Obj.Mdl.Inputs.PSF_MATERIAL_ULS);
            fyd = Obj.Mdl.Inputs.yieldStrengthChar ./ psf;
        end

        function fyd = calc_design_yield_strength_jpn(Obj)
            % Returns design value of flange material yield strength for Japanese designs.
            %
            % Differences to "calc_design_yield_strength_row":
            % - For JPN market designs, the flange material PSFs are not altered for robustness checks. This
            %   is embedded in other factors.

            psf = ones(1, Obj.Mdl.Loads.nLoadSets) * ...
                Obj.Mdl.Inputs.PSF_CMPCLASS2_ULS * Obj.Mdl.Inputs.PSF_MATERIAL_ULS;
            fyd = Obj.Mdl.Inputs.yieldStrengthChar ./ psf;
        end

        function psf = calc_strength_psf(Obj, psfFromInputs)
            % Returns PSF on strength for each load set.
            % Uses input PSF value unless a load set describes a "robustness check"; these load sets are to be
            % assessed without PSFs.
            %
            % psfFromInputs: [double, 1x1] Combined PSF on flange material for ULS, from USAIN inputs
            % psf: [double, 1xM] Combined PSF on flange material for ULS, to be used in calculations

            tags = {Obj.Mdl.Loads.Uls.tag};
            isRobustChk = contains(tags, Milk.ExtremeLoads.EVENT_TAGS_ROBUST);
            psf = ones(1, Obj.Mdl.Loads.nLoadSets) * psfFromInputs;
            psf(isRobustChk) = 1.00;
        end

        function ftrd = calc_design_tension_resistance_bolt(Obj)
            % Returns design value of tension resistance of bolt (symbol: FtRd)

            psf = Obj.calc_strength_psf(Obj.Mdl.Inputs.PSF_BOLT_RESISTANCE);
            ftrd = 0.9 * Obj.Mdl.Bolt.ftRc ./ psf;
        end

    end

    methods (Static)

        function UlsCondit = get_uls_condition_for_countrycode(Condits, countryCode)
            % Returns concrete UlsCondition given input countryCode
            %
            % Condits:     [UsainUtils.ConditionContainer]
            % countryCode: [char] Country code
            % UlsCondit:   [UsainUtils.UlsCondition subclass] ULS condition corresponding to countryCode

            switch upper(countryCode)
                case 'ROW'
                    UlsCondit = Condits.Uls;
                case 'JPN'
                    UlsCondit = Condits.UlsJpn;
                otherwise
                    error('UlsCondition:UnsupportedCountryCode', ...
                        'Country code %s is not supported. Choose from: %s', ...
                        countryCode, strjoin(USAIN.VALID_COUNTRY_CODES, ', '));
            end
        end

    end
end
