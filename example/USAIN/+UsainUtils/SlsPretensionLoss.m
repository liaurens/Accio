classdef SlsPretensionLoss < UsainUtils.ICondition
    % SLSPRETENSIONLOSS Condition for pretension loss under SLS loads
    %   The calculation method followed here is based on section 7.3 of
    %   - M. Seidel. Zur Bemessung geschraubter Ringflanschverbindungen von
    %     Windenergieanlagen. Schriftenreihe des Instituts fuer Stahlbau der
    %     Universitaet Hannover. Shaker, 2001.

    properties
        preload double % [Nx1] Preload in bolt

        description string = "SLS pretension loss"
    end
    properties (Dependent)
        utilRatioGeom   % Utilization ratio corresponding to geometric constraint c/d_b <= 4
    end
    properties (Constant)
        TOGGLE_NAME = 'DO_ASSESS_SLS_PRETENSION'

        POINT_LOAD_SHARE = 0.5
        N_LOOKUP = 50   % Number of stress evaluation points along the bolt hole circumference
    end

    methods

        function Obj = SlsPretensionLoss(varargin)
            % Call superclass constructor
            Obj@UsainUtils.ICondition(varargin{:});

            % Set the target utililzation ratio to 1.2 to allow for 20% over-utilization (as per design rules)
            Obj.targetUtilRatio = 1.20;
        end

        function bool = do_assess(Obj)
            % Overloads parent method `UsainUtils.ICondition.do_assess()`
            isLFlange = strcmp(Obj.Mdl.Inputs.flangeType, 'L');
            bool = Obj.Mdl.Inputs.(Obj.TOGGLE_NAME) && isLFlange;
        end

        function evaluate_condition(Obj)

            Obj.preload = usain.fastener.get_preload(Obj.Mdl.Tool.defaultPreload, ...
                Obj.Mdl.Inputs.SlsPretension.CUSTOM_PRELOAD, 1);

            fSegment = Obj.Mdl.Segment.calc_segment_force( ...
                Obj.Mdl.Loads.maxFlsMxy + Obj.Mdl.Loads.inclinMomentFlsDesign, ...
                -Obj.Mdl.Loads.deadWeightFavorDesign);

            xForce = Obj.calc_force_application_distance();
            [shearInt, momentInt] = Obj.calc_section_loads_at_edge(fSegment, xForce);

            sigmaZ = Obj.calc_longitudinal_stress();
            sigmaX = Obj.calc_lateral_stress(shearInt, momentInt);

            % Find max stress along bolthole circumference
            [sigmaXMax, ~] = max(sigmaX, [], 2);

            % Evaluate Von-mises yield criterion to determine utilization
            sigmaVm = sqrt(sigmaZ.^2 + sigmaXMax.^2 - (sigmaZ .* sigmaXMax));
            ur = sigmaVm ./ Obj.Mdl.Inputs.yieldStrengthChar;
            Obj.utilRatio = Obj.squeeze_dims(ur);

            % Print (suppressable) warning in case of infeasible design(s)
            % NOTE: The warning is to be suppressed during optimisation
            Obj.verify_feasibility();
        end

        function xForce = calc_force_application_distance(Obj)

            diamContact = usain.fastener.calc_contact_diameter(Obj.Mdl.Nut.diam, Obj.Mdl.Wash.diamOut, ...
                Obj.Mdl.Wash.len);
            rHole = Obj.Mdl.Inputs.diamBoltHole / 2;
            rContact = diamContact / 2;

            theta = 2 * acos(rHole ./ rContact);
            xForce = 4 / 3 .* rContact .* sin(theta / 2).^3 ./ (theta - sin(theta));
        end

        function [shear, moment] = calc_section_loads_at_edge(Obj, fApplied, xForce)

            fPretension = Obj.preload;
            rHole = Obj.Mdl.Inputs.diamBoltHole / 2;
            b = Obj.Mdl.Segment.distForce;

            fInt = (fPretension * Obj.POINT_LOAD_SHARE) / 2;
            shear = -fApplied + fInt;
            moment = fApplied .* (b - rHole) - fInt .* (xForce - rHole);
        end

        function sigmaZ = calc_longitudinal_stress(Obj)

            diamContact = usain.fastener.calc_contact_diameter(Obj.Mdl.Nut.diam, Obj.Mdl.Wash.diamOut, ...
                Obj.Mdl.Wash.len);
            dHole = Obj.Mdl.Inputs.diamBoltHole;
            dContact = diamContact;
            thickn = Obj.Mdl.Space.thickness;
            fPretension = Obj.preload;

            rHole = dHole / 2;
            rContact = dContact / 2;

            alphaZ = min(0.60 * dHole ./ thickn, 1);
            sigmaZ = -alphaZ .* fPretension ./ (pi * (rContact.^2 - rHole.^2));
        end

        function sigmaX = calc_lateral_stress(Obj, shearInt, momentInt)

            c = Obj.Mdl.Segment.distBolt;
            dHole = Obj.Mdl.Inputs.diamBoltHole;
            rHole = dHole / 2;
            fPretension = Obj.preload;
            thickn = Obj.Mdl.Space.thickness;

            distrLoadInt = (1 - Obj.POINT_LOAD_SHARE) .* fPretension ./ dHole;

            x = bsxfun(@times, linspace(0, 1, Obj.N_LOOKUP), dHole);
            xSquared = x.^2;

            % See [Seidel eq 149] if you can't read this
            momentX = bsxfun(@minus, momentInt, bsxfun(@times, shearInt, x) + ...
                0.5 * bsxfun(@times, distrLoadInt, xSquared));

            % See [Seidel eq 151] if you can't read this
            sectionModulus = bsxfun(@times, ...
                bsxfun(@minus, c, 2 * sqrt(2 * bsxfun(@times, x, rHole) - xSquared)), thickn.^2 ./ 6);
            sigmaX = momentX ./ sectionModulus;
        end

        function verify_feasibility(Obj)
            % Although the isFeasible property is forced to be always true, this
            % method can be called to check for over-utilised design points.

            if any(Obj.utilRatio(:) > Obj.targetUtilRatio)
                Obj.warning('USAIN:SlsPretensionLoss:InfeasibleDesign', ...
                    ['Chances of pretension loss due to SLS loading!\n', ...
                    'This also indicates severe bending stresses in the flange neck. ', ...
                    'Further verification may be required.', ...
                    '\n\n\t==> Please check the SGRE Design Rules and/or contact topic owner.']);
            end
        end

        function value = get_isFeasible_impl(Obj)
            % Overloading parent method to mimic overloading get.isFeasible

            % Always return true (this condition is merely a check, not a design
            % driver)
            value = Obj.is_always_feasible();
        end

        %%%%% == GETTERS / SETTERS == %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function value = get.utilRatioGeom(Obj)
            if Obj.doAssess
                value = Obj.Mdl.Segment.distBolt ./ (4 * Obj.Mdl.Bolt.diam);
            else
                % Always return a value to prevent an error when FilePort calls this method while the condition is not
                % assessed
                value = [];
            end
        end

    end
end
