classdef PostLoadManipulations < VarargToClassProp & logging.Loggable

    properties
        Inputs
        iElem
    end

    methods

        function ManipulatedInputs = run(Obj)

            Obj.set_inputs_from_structural_model();

            ManipulatedInputs = Obj.Inputs;

        end

        function set_inputs_from_structural_model(Obj)
            % If a StructuralModel is provided, use it's data to set blank inputs in the USAIN input file.
            % USAIN user input will be governing!

            if isempty(Obj.Inputs.structureInpFilePath)
                return
            end

            % First set the element number of StructuralModel which relate to the flange
            Obj.set_flange_element_index();
            Obj.set_diameter();
            Obj.set_flange_type();
            Obj.set_nose_thickness();

        end

        function set_flange_element_index(Obj)
            % Get indices of element(s) representing this flange
            TOL_Z = 1e-3;
            Obj.iElem = find(Obj.Inputs.zFlange >= (Obj.Inputs.StrMdl.Inp.Plate.Parsed.zCoordTop - TOL_Z) & ...
                Obj.Inputs.zFlange <= (Obj.Inputs.StrMdl.Inp.Plate.zCoordBot + TOL_Z));
        end

        function set_diameter(Obj)
            if isnan(Obj.Inputs.diameter)
                mdlVarName = 'diamTop';
                diamElem = Unit.mm.to_si(Obj.Inputs.StrMdl.Inp.Plate.fTab(mdlVarName, Obj.iElem(1)));
                Obj.Logger.info(['Grabbing value for "diameter" from StructuralModel input file ', ...
                    '(variable "%s"): %gmm'], ...
                    mdlVarName, Unit.mm.from_si(diamElem));
                Obj.Inputs.diameter = diamElem;
            end
        end

        function set_flange_type(Obj)
            if isempty(Obj.Inputs.flangeType)
                mdlVarName = 'elemType';
                elemType = Obj.Inputs.StrMdl.Inp.Plate.fTab(mdlVarName, Obj.iElem(1));
                Obj.Logger.info( ...
                    'Grabbing value for "flangeType" from StructuralModel input file (variable "elemType"): %s', ...
                     elemType(1));
                Obj.Inputs.flangeType = elemType(1);
            end
        end

        function set_nose_thickness(Obj)
            % Set thicknNoseUp and/or thicknNoseLo
            for iEl = 1:numel(Obj.iElem)
                varName = sprintf('thicknNose%s', iif(iEl == 1, 'Up', 'Lo'));
                if isnan(Obj.Inputs.(varName))
                    mdlVarName = 'wallThickn';
                    thicknElem = Unit.mm.to_si(Obj.Inputs.StrMdl.Inp.Plate.fTab(mdlVarName, Obj.iElem(iEl)));
                    Obj.Logger.info('Grabbing value for "%s" from StructuralModel input file: %gmm', ...
                        varName, Unit.mm.from_si(thicknElem));
                    Obj.Inputs.(varName) = thicknElem;

                    if numel(Obj.iElem) == 1 && isnan(Obj.Inputs.thicknNoseLo)
                        % Assume symmetric flange connection
                        Obj.Logger.info( ...
                            'Grabbing value for "thicknNoseLo" from StructuralModel input file: %gmm', ...
                            Unit.mm.from_si(thicknElem));
                        Obj.Inputs.thicknNoseLo = thicknElem;
                    end
                end
            end
        end

    end

end
