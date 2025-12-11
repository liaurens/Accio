classdef EquivalentScfOutputStep < runner.BaseStep & logging.Loggable
    % This step prepares a struct with StructuralModel flange labels and equivalent SCFs, to be used in STIFT.
    % A TEXACO post-run trigger will convert this struct to inputs in the STIFT input file.

    methods

        function Obj = EquivalentScfOutputStep(varargin)

            Obj = assign_varargin_2_classprop(Obj, varargin{:});

            Obj.InputKeys.Inputs = usain.DataKeys.Inputs;
            Obj.InputKeys.SelectedConditionCollection = usain.DataKeys.SelectedConditionCollection;
            Obj.InputKeys.StructuralModel = usain.DataKeys.StructuralModel;

            Obj.OutputKeys.FlangeNeckScfOutputData = usain.DataKeys.FlangeNeckScfOutputData;
        end

        function str = print_label(~)
            str = 'Prepare equivalent SCF output data';
        end

        function run(Obj)
            AllConditions = Obj.get(Obj.InputKeys.SelectedConditionCollection);
            Inputs = Obj.get(Obj.InputKeys.Inputs);
            StrMdl = Obj.get(Obj.InputKeys.StructuralModel);

            Condition = AllConditions.get_condition_from_classname('UsainUtils.FlangeNeckScf');
            assert(length(Condition) == 1, 'Expected single condition.');

            % Find index/indices of StructuralModel elements pertaining to the assessed flange connection
            TOL_Z = 1e-3;
            iElem = find( ...
                Inputs.zFlange >= (StrMdl.Inp.Plate.Parsed.zCoordTop - TOL_Z) & ...
                Inputs.zFlange <= (StrMdl.Inp.Plate.zCoordBot + TOL_Z));
            isAtStructureBot = abs(Inputs.zFlange - max(StrMdl.Levels.zRange)) < TOL_Z;
            isAtStructureTop = abs(Inputs.zFlange - min(StrMdl.Levels.zRange)) < TOL_Z;

            % Define index masks for extract the SCF(s) on the inside and outside.
            % By default, extract from both the upper and lower flange in the connection. For a flange connection at the
            % bottom of the StructuralModel, only select the top flange in the connection (as the other flange is not
            % modelled). Vice versa for flange connections at the top of the StructuralModel.
            isScfInside = [Condition.I_IN_UP, Condition.I_IN_LO];
            isScfOutside = [Condition.I_OUT_UP, Condition.I_OUT_LO];
            if isAtStructureBot
                isScfInside = isScfInside(1);
                isScfOutside = isScfOutside(1);
            elseif isAtStructureTop
                isScfInside = isScfInside(2);
                isScfOutside = isScfOutside(2);
            end

            % Store flange labels from StructuralModel and equivalent SCFs in a struct. Store the maximum SCFs in case
            % of multiple load sets.
            FlangeNeckScfOutputData.labels = string(StrMdl.Inp.Plate.Parsed.elemLabel(iElem)');
            FlangeNeckScfOutputData.bendingScfInside = max(Condition.scfEqv(isScfInside, :), [], 2)';
            FlangeNeckScfOutputData.bendingScfOutside = max(Condition.scfEqv(isScfOutside, :), [], 2)';
            Obj.set(Obj.OutputKeys.FlangeNeckScfOutputData, FlangeNeckScfOutputData);
        end

        function pass = is_active(Obj)
            Inputs = Obj.get(Obj.InputKeys.Inputs);
            pass = ...
                Inputs.DO_ASSESS_FLANGE_NECK_SCF && ...
                Inputs.flangeType == usain.inputs.FlangeType.L && ...
                ~isempty(Inputs.structureInpFilePath);
        end

    end
end
