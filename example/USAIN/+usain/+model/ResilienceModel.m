classdef ResilienceModel

    properties
        % Data structures for fastener assemblies components, as structs because that's how USAIN works. The original
        % data in these structs come from usain.fastener.FastenerData, usain.fastener.ExtenderData, etc.
        Bolt struct
        Extender struct
        Nut struct
        Washer struct

        eModulusBolt (1, 1) double = 210e9
        eModulusFlange (1, 1) double = 210e9
        doIgnoreExtender (1, 1) logical
        diameterBoltHole (1, :) double
        flangeThickness (1, :) double

        resilienceBolt (1, :) double
        resilienceClampedParts (1, :) double
        resilienceFlanges (1, :) double
        bendingResilienceBolt (1, :) double
        loadFactor (1, :) double
    end

    methods

        function resilience = calc_resilience_fastener(Obj)
            % Helper for calculating the axial resilience of both studs and hex bolts

            % Generally, studs are used so compute resilience for studs
            resilience = Obj.calc_resilience_iso_stud();

            % If bolts are present in the design space, override the respective indices
            isHexBolt = strcmpi(Obj.Bolt.type, 'hex');
            if any(isHexBolt)
                resilienceHexBolt = Obj.calc_resilience_hv_bolt();
                resilience(isHexBolt) = resilienceHexBolt(isHexBolt);
            end
        end

        function resilience = calc_resilience_hv_bolt(Obj)
            % Computes axial resilience of hex bolt
            % The (elastic) resilience of the bolt is a summation of the various cylindrical elements of different
            % lengths and areas in the bolt assembly, according to section 5.1, eq.3 in VDI2230:2003.
            % The different bolt parts considered are:
            % - Bolt head
            % - Bolt shank (bolt part without thread)
            % - Bolt thread (gripped and engaged thread)
            % - Load carrying part of nut

            eMod = Obj.eModulusBolt;  % same for all components

            % Bolt head
            headArea = Obj.calc_area(Obj.Bolt.diam);
            headLength = 0.5 * Obj.Bolt.diam;
            headResilience = Obj.calc_axial_resilience(headArea, headLength, eMod);

            % Bolt shank: If extender contribution is ignored, subtract the extender length from the shank length
            shankArea = Obj.calc_area(Obj.Bolt.diam);
            if Obj.doIgnoreExtender
                shankLength = Obj.Bolt.len - Obj.Bolt.lenThread - Obj.Extender.len;
                grippedThreadLength = 2 * (Obj.flangeThickness + Obj.Washer.len) - shankLength;
            else
                shankLength = Obj.Bolt.len - Obj.Bolt.lenThread;
                grippedThreadLength = 2 * (Obj.flangeThickness + Obj.Washer.len) - shankLength + Obj.Extender.len;
            end
            shankResilience = Obj.calc_axial_resilience(shankArea, shankLength, eMod);

            % Gripped threads: note that `shankLength` includes or excludes the extender contribution based on the logic
            % above
            threadArea = Obj.calc_area(Obj.Bolt.minorDiameter);
            grippedThreadResilience = Obj.calc_axial_resilience(threadArea, grippedThreadLength, eMod);
            % TODO: `grippedThreadResilience` can become negative, probably due to wrong consideration of
            % `doIgnoreExtender`. This is not physical and needs to be re-considered.

            % Engaged threads
            engagedThreadLength = 0.5 * Obj.Bolt.diam;
            engagedThreadResilience = Obj.calc_axial_resilience(threadArea, engagedThreadLength, eMod);

            % Nut (load carrying length)
            nutArea = Obj.calc_area(Obj.Bolt.diam);
            nutLength = 0.4 * Obj.Bolt.diam;
            nutResilience = Obj.calc_axial_resilience(nutArea, nutLength, eMod);

            % Sum component resilience and return total axial resilience
            resilience = headResilience + shankResilience + grippedThreadResilience + engagedThreadResilience + ...
                nutResilience;
        end

        function resilience = calc_resilience_iso_stud(Obj)
            % Computes axial resilience of iso stud
            % Similar to `calc_resilience_hv_bolt()`, but for ISO studs (symmetrically threaded).

            eMod = Obj.eModulusBolt;  % same for all components

            % Shank: If extender contribution is ignored, subtract the extender length from the shank length
            % NOTE: Shank diameter computed according to ISO724 (pitch diameter), following ZPS 1037252, Table D1.1.-3
            shankArea = Obj.calc_area(Obj.Bolt.pitchDiameter);
            if Obj.doIgnoreExtender
                shankLength = Obj.Bolt.len - 2 * Obj.Bolt.lenThread - Obj.Extender.len;
                grippedThreadLength = 2 * (Obj.flangeThickness + Obj.Washer.len) - shankLength;
            else
                shankLength = Obj.Bolt.len - 2 * Obj.Bolt.lenThread;
                grippedThreadLength = 2 * (Obj.flangeThickness + Obj.Washer.len) - shankLength + Obj.Extender.len;
            end
            shankResilience = Obj.calc_axial_resilience(shankArea, shankLength, eMod);

            % Gripped threads: note that `shankLength` includes or excludes the extender contribution based on the logic
            % above
            threadArea = Obj.calc_area(Obj.Bolt.minorDiameter);
            grippedThreadResilience = Obj.calc_axial_resilience(threadArea, grippedThreadLength, eMod);
            % TODO: `grippedThreadResilience` can become negative, probably due to wrong consideration of
            % `doIgnoreExtender`. This is not physical and needs to be re-considered.

            % Engaged threads
            engagedThreadLength = 0.5 * Obj.Bolt.diam;
            engagedThreadResilience = Obj.calc_axial_resilience(threadArea, engagedThreadLength, eMod);

            % Nut (load carrying length)
            nutArea = Obj.calc_area(Obj.Bolt.diam);
            nutLength = 0.4 * Obj.Bolt.diam;
            nutResilience = Obj.calc_axial_resilience(nutArea, nutLength, eMod);

            % Sum component resilience and return total axial resilience
            resilience = shankResilience + grippedThreadResilience + 2 * engagedThreadResilience + 2 * nutResilience;
        end

        function resilience = calc_resilience_washers(Obj)
            % Computes axial resilience of washers (both washers combined)
            % The resilience is computed according to eq 53 in Petersen's Stahlbau

            washerLength = Obj.Washer.len;
            washerArea = (pi / 4) * (Obj.Washer.diamOut.^2 - Obj.Washer.diamIn.^2);
            resilience = 2 * Obj.calc_axial_resilience(washerArea, Obj.Washer.len, Obj.eModulusBolt);
            resilience(washerLength <= 1e-6) = 0;
        end

        function resilience = calc_resilience_extender(Obj)
            % Computes axial resilience of extender
            % The resilience is computed according to eq 53 in Petersen's Stahlbau

            if Obj.doIgnoreExtender
                resilience = zeros(size(Obj.Extender.len));
            else
                extenderLength = Obj.Extender.len;
                extenderArea = (pi / 4) * (Obj.Extender.diamOut.^2 - Obj.Extender.diamIn.^2);
                resilience = Obj.calc_axial_resilience(extenderArea, Obj.Washer.len, Obj.eModulusFlange);
                resilience(extenderLength <= 1e-6) = 0;
            end
        end

        function resilience = calc_resilience_flanges(Obj)
            % Computes axial resilience of flanges (both combined)
            % The resilience is computed according to the assumed cylindrical stress sleeve originally proposed by
            % Petersen in Stahlbau (eq 63). The stress cone computation described in VDI2230 is considered to be
            % non-conservative, especially when combined with the bolt force model from Schmidt-Neuper.

            diameterContact = usain.fastener.calc_contact_diameter(Obj.Nut.diam, Obj.Washer.diamOut, Obj.Washer.len);
            areaSleeve = (pi / 4) * ((diameterContact + 0.2 * Obj.flangeThickness).^2 - Obj.diameterBoltHole.^2);
            resilience = 2 * Obj.calc_axial_resilience(areaSleeve, Obj.flangeThickness, Obj.eModulusFlange);
        end

        function resilience = calc_bending_resilience_fastener(Obj)
            % Helper for calculating the bending resilience of both studs and hex bolts

            % Generally, studs are used so compute bending resilience for studs
            resilience = Obj.calc_bending_resilience_iso_stud();

            % If bolts are present in the design space, override the respective indices
            isHexBolt = strcmpi(Obj.Bolt.type, 'hex');
            if any(isHexBolt)
                resilienceHexBolt = Obj.calc_bending_resilience_hv_bolt();
                resilience(isHexBolt) = resilienceHexBolt(isHexBolt);
            end

            % For debugging: A simplification that shows to give reasonably similar results:
            % beta = 192 * Obj.flangeThickness ./ (Obj.eModulusBolt .* pi .* Obj.Bolt.diam.^4);
        end

        function resilience = calc_bending_resilience_hv_bolt(Obj)
            % Computes bending resilience of hex bolt
            % Similar to `calc_resilience_hv_bolt()`, but for bending resilience.

            eMod = Obj.eModulusBolt;  % same for all components

            % Bolt head
            headLength = 0.5 * Obj.Bolt.diam;
            headResilience = Obj.calc_bending_resilience(Obj.Bolt.diam, headLength, eMod);

            % Bolt shank: If extender contribution is ignored, subtract the extender length from the shank length
            if Obj.doIgnoreExtender
                shankLength = Obj.Bolt.len - Obj.Bolt.lenThread - Obj.Extender.len;
                grippedThreadLength = 2 * (Obj.flangeThickness + Obj.Washer.len) - shankLength;
            else
                shankLength = Obj.Bolt.len - Obj.Bolt.lenThread;
                grippedThreadLength = 2 * (Obj.flangeThickness + Obj.Washer.len) - shankLength + Obj.Extender.len;
            end
            shankResilience = Obj.calc_bending_resilience(Obj.Bolt.diam, shankLength, eMod);

            % Gripped threads: note that `shankLength` includes or excludes the extender contribution based on the logic
            % above
            grippedThreadResilience = Obj.calc_bending_resilience(Obj.Bolt.minorDiameter, grippedThreadLength, eMod);

            % Engaged threads
            engagedThreadLength = 0.5 * Obj.Bolt.diam;
            engagedThreadResilience = Obj.calc_bending_resilience(Obj.Bolt.minorDiameter, engagedThreadLength, eMod);

            % Nut (load carrying length)
            nutLength = 0.4 * Obj.Bolt.diam;
            nutResilience = Obj.calc_bending_resilience(Obj.Bolt.diam, nutLength, eMod);

            % Sum component resilience and return total bending resilience
            resilience = headResilience + shankResilience + grippedThreadResilience + engagedThreadResilience + ...
                nutResilience;
        end

        function resilience = calc_bending_resilience_iso_stud(Obj)
            % Computes bending resilience of iso stud
            % Similar to `calc_bending_resilience_hv_bolt()`, but for ISO studs (symmetrically threaded).

            eMod = Obj.eModulusBolt;  % same for all components

            % Bolt shank: If extender contribution is ignored, subtract the extender length from the shank length
            if Obj.doIgnoreExtender
                shankLength = Obj.Bolt.len - 2 * Obj.Bolt.lenThread - Obj.Extender.len;
                grippedThreadLength = 2 * (Obj.flangeThickness + Obj.Washer.len) - shankLength;
            else
                shankLength = Obj.Bolt.len - 2 * Obj.Bolt.lenThread;
                grippedThreadLength = 2 * (Obj.flangeThickness + Obj.Washer.len) - shankLength + Obj.Extender.len;
            end
            shankResilience = Obj.calc_bending_resilience(Obj.Bolt.pitchDiameter, shankLength, eMod);

            % Gripped threads: note that `shankLength` includes or excludes the extender contribution based on the logic
            % above
            grippedThreadResilience = Obj.calc_bending_resilience(Obj.Bolt.minorDiameter, grippedThreadLength, eMod);

            % Engaged threads
            engagedThreadLength = 0.5 * Obj.Bolt.diam;
            engagedThreadResilience = Obj.calc_bending_resilience(Obj.Bolt.minorDiameter, engagedThreadLength, eMod);

            % Nut (load carrying length)
            nutLength = 0.4 * Obj.Bolt.diam;
            nutResilience = Obj.calc_bending_resilience(Obj.Bolt.diam, nutLength, eMod);

            % Sum component resilience and return total bending resilience
            resilience = shankResilience + grippedThreadResilience + 2 * engagedThreadResilience + 2 * nutResilience;
        end

    end

    methods (Access = private)

        function area = calc_area(~, diameter)
            % Helper method to compute area from diameter
            area = (pi / 4) * diameter.^2;
        end

        function resil = calc_axial_resilience(~, area, len, eModulus)
            % Helper method to compute resilience of cylindrical component
            resil = len ./ (area .* eModulus);
        end

        function resil = calc_bending_resilience(~, diameter, len, eModulus)
            % Helper method to compute resilience of cylindrical component
            inertia = (pi / 64) * diameter.^4;
            resil = len ./ (inertia .* eModulus);
        end

    end

    methods (Static)

        function Obj = from_flange_model(FlangeModel)

            Obj = usain.model.ResilienceModel();

            % Set inputs for resilience calculations
            % NOTE: Fastener assembly data is transposed because this class works with row vectors
            Obj.Bolt = structfun(@(x) x', FlangeModel.Bolt, 'uni', 0);
            Obj.Extender = structfun(@(x) x', FlangeModel.Extr, 'uni', 0);
            Obj.Nut = structfun(@(x) x', FlangeModel.Nut, 'uni', 0);
            Obj.Washer = structfun(@(x) x', FlangeModel.Wash, 'uni', 0);
            Obj.eModulusBolt = FlangeModel.Inputs.E_BOLT;
            Obj.eModulusFlange = FlangeModel.Inputs.E_FLANGE;
            Obj.doIgnoreExtender = FlangeModel.Inputs.IGNORE_BOLT_EXTENDER;
            Obj.diameterBoltHole = FlangeModel.Inputs.diamBoltHole;
            Obj.flangeThickness = FlangeModel.Space.thickness;

            % Compute resilience values and load factor
            Obj.resilienceBolt = Obj.calc_resilience_fastener();
            Obj.resilienceFlanges = Obj.calc_resilience_flanges();
            resilienceWashers = Obj.calc_resilience_washers();
            resilienceExtender = Obj.calc_resilience_extender();
            Obj.resilienceClampedParts = Obj.resilienceFlanges + resilienceWashers + resilienceExtender;
            Obj.bendingResilienceBolt = Obj.calc_bending_resilience_fastener();
            Obj.loadFactor = Obj.resilienceFlanges ./ (Obj.resilienceClampedParts + Obj.resilienceBolt);
        end

    end
end
