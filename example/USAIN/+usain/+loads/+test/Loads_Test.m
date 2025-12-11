classdef (SharedTestFixtures = {fixtures.SilentlyLogFixture(logging.Level.ERROR)}) ...
        Loads_Test < Unittest.TestCase  & matlab.mock.TestCase

    properties (TestParameter)
        % List with DO_ASSESS_* input toggles that require FLS loads
        flsToggles = {'DO_ASSESS_FLS', 'DO_ASSESS_GAPPING', 'DO_ASSESS_SLS_PRETENSION', ...
            'DO_ASSESS_FLANGE_NECK_SCF'}

        % List with DO_ASSESS_* input toggles that require ULS loads
        ulsToggles = {'DO_ASSESS_ULS', 'DO_ASSESS_ULS_JPN'}

        % List with DO_ASSESS_* input toggles that require S1 loads
        s1Toggles = {'DO_ASSESS_BOLT_PLASTICITY', 'DO_ASSESS_FLANGE_PLASTICITY'}
    end

    methods (Test, TestTags = {'integration'})

        function setup__dead_weight_fls_and_uls(Obj)
            % GIVEN inputs from fixture, etc., to call setup() successfully
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 1)).data;
            Inputs = Obj.create_or_update_input_struct_with_all_conditions_disabled(Inputs);
            Inputs.DEAD_WEIGHT = 1000;
            Inputs.PSF_FAVORABLE_LOADS = 0.9;
            Inputs.MACRO_GEOMETRIC_SCF = 1.1;
            Inputs.INCLINATION_MOMENT = 9876;
            Inputs.ULS_BENDING_MOMENT = 654321;
            Inputs.Loads.ulsFilePath = {'foo', 'bar'};  % 2 load sets
            StrMdl = '';
            DummyMilk.Uls = Milk.ExtremeLoads();

            % WHEN
            Loads = usain.loads.Loads.setup(Inputs, DummyMilk, StrMdl);

            % THEN
            Obj.verifyEqual(Loads.deadWeightChar, 1000, 'AbsTol', 1e-4);
            Obj.verifyEqual(Loads.deadWeightFavorDesignUls, 900, 'AbsTol', 1e-4);
            Obj.verifyEqual(Loads.deadWeightFavorDesign, 990, 'AbsTol', 1e-4);
        end

        function setup__uls_loads_by_expert_inputs__happy(Obj)
            % GIVEN inputs from fixture, no structural model and loads via expert inputs, hence no Milk loading
            % Also ensure that no design checks are required, so no importing of loads is done.
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 1)).data;
            Inputs = Obj.create_or_update_input_struct_with_all_conditions_disabled(Inputs);
            Inputs.DEAD_WEIGHT = 12345;
            Inputs.INCLINATION_MOMENT = 9876;
            Inputs.ULS_BENDING_MOMENT = 654321;
            Inputs.Loads.ulsFilePath = {'foo', 'bar'};  % 2 load sets
            StrMdl = '';
            DummyMilk.Uls = Milk.ExtremeLoads();

            % WHEN
            Loads = usain.loads.Loads.setup(Inputs, DummyMilk, StrMdl);

            % THEN
            Obj.verifyEqual(Loads.deadWeightChar, Inputs.DEAD_WEIGHT, 'AbsTol', 1e-10);
            Obj.verifyEqual(Loads.deadWeightFavorDesignUls, Inputs.DEAD_WEIGHT * Inputs.PSF_FAVORABLE_LOADS, 'AbsTol', 1e-10); % mh:ignore_style

            Obj.verifySize(Loads.inclinMomentChar, [1, 2]);
            Obj.verifySize(Loads.inclinMomentDesign, [1, 2]);
            Obj.verifySize(Loads.ulsMxyDesign, [1, 2]);

            Obj.verifyEqual(Loads.inclinMomentChar(1), Inputs.INCLINATION_MOMENT, 'AbsTol', 1e-10);
            Obj.verifyEqual(Loads.inclinMomentChar(1), Loads.inclinMomentChar(2), 'AbsTol', 1e-10);
            Obj.verifyEqual(Loads.inclinMomentDesign(1), Inputs.INCLINATION_MOMENT * Milk.ExtremeLoads.PSF_GRAVITY, 'AbsTol', 1e-10); % mh:ignore_style
            Obj.verifyEqual(Loads.inclinMomentDesign(1), Loads.inclinMomentDesign(2), 'AbsTol', 1e-10); % mh:ignore_style
            Obj.verifyEqual(Loads.ulsMxyDesign(1), Inputs.ULS_BENDING_MOMENT, 'AbsTol', 1e-10);
            Obj.verifyEqual(Loads.ulsMxyDesign(1), Loads.ulsMxyDesign(2), 'AbsTol', 1e-10);
        end

        function setup__no_uls_expert_inputs__no_structuralmodel__happy(Obj)
            % GIVEN inputs from fixture, no structural model.
            % Also ensure that no design checks are required, so no importing of loads is done.
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 1)).data;
            Inputs = Obj.create_or_update_input_struct_with_all_conditions_disabled(Inputs);
            StrMdl = '';
            DummyMilk.Uls = Milk.ExtremeLoads();

            % WHEN
            Loads = usain.loads.Loads.setup(Inputs, DummyMilk, StrMdl);

            % THEN
            Obj.verifyEqual(Loads.deadWeightChar, 0, 'AbsTol', 1e-10);
            Obj.verifyEqual(Loads.deadWeightFavorDesignUls, 0, 'AbsTol', 1e-10);
            Obj.verifyEqual(Loads.inclinMomentChar, 0, 'AbsTol', 1e-10);
            Obj.verifyEqual(Loads.inclinMomentDesign, 0, 'AbsTol', 1e-10);
        end

        function setup__fls_inclination_moment_from_override(Obj)
            % GIVEN inputs from fixture, with override set
            % Also ensure that no design checks are required, so no importing of loads is done.
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 1)).data;
            Inputs = Obj.create_or_update_input_struct_with_all_conditions_disabled(Inputs);
            Inputs.INCLINATION_MOMENT_FLS = 1234.56;
            StrMdl = '';
            DummyMilk.Uls = Milk.ExtremeLoads();

            % WHEN
            Loads = usain.loads.Loads.setup(Inputs, DummyMilk, StrMdl);

            % THEN expect 1234.56 * 1.1 = 1358.016 (the PSF on gravity loads is 1.1)
            Obj.verifyEqual(Loads.inclinMomentFlsDesign, 1358.016, 'AbsTol', 1e-10);
        end

        function setup__s1_loads_only(Obj)
            % GIVEN inputs such that only S1 loads file is imported
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 1)).data;
            Inputs = Obj.create_or_update_input_struct_with_all_conditions_disabled(Inputs);
            Inputs.DO_ASSESS_BOLT_PLASTICITY = true;
            StrMdl = [];
            DummyMilk.S1 = Milk.ServiceAbilityLoads();
            DummyMilk.S1.Channels = ChannelSet();
            DummyMilk.S1.Channels.labels = {'foo', 'bar'};
            DummyMilk.S1.Channels.zLevels = {[-200, 200]};
            DummyMilk.S1.loads = [123, 123];
            Inputs.S1_BENDING_MOMENT = nan;

            % WHEN
            Loads = usain.loads.Loads.setup(Inputs, DummyMilk, StrMdl);

            % THEN
            Obj.verifyEqual(Loads.maxS1MomentDesign, 123, 'RelTol', 1e-4);
        end

        function setup__s1_override_only(Obj)
            % GIVEN inputs such that only S1 loads via expert inputs is set
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 1)).data;
            Inputs = Obj.create_or_update_input_struct_with_all_conditions_disabled(Inputs);
            Inputs.DO_ASSESS_BOLT_PLASTICITY = true;
            Inputs.S1_BENDING_MOMENT = 12345;
            StrMdl = [];
            DummyMilk.S1 = Milk.ServiceAbilityLoads();
            DummyMilk.S1.Channels = ChannelSet();
            DummyMilk.S1.Channels.labels = {'foo', 'bar'};
            DummyMilk.S1.Channels.zLevels = {[-200, 200]};
            DummyMilk.S1.loads = [123, 123];

            % WHEN
            Loads = usain.loads.Loads.setup(Inputs, DummyMilk, StrMdl);

            % THEN
            Obj.verifyEqual(Loads.maxS1MomentDesign, 12345, 'RelTol', 1e-4);
        end

    end

    methods (Test, TestTags = {'unit'})

        function get_max_sls_moment__partial_s1_loads(Obj)
            % GIVEN a Loads object where S1 loads are defined for only some load sets (not all)
            Loads = usain.loads.Loads();
            Loads.maxS1MomentDesign = [1, 2, nan, 4];
            Loads.maxFlsMxy = [10, 20, 30, 40];

            % WHEN
            actual = Loads.get_max_sls_moment();

            % THEN
            Obj.verifyEqual(actual, [1, 2, 30, 4]);
        end

        function check_is_required_fls__one_fls_condition_active(Obj, flsToggles)
            % GIVEN the parametrized inputs assigned to a struct, such that it
            % reflects USAIN inputs where one FLS condition is active
            DummyInputs = Obj.create_or_update_input_struct_with_all_conditions_disabled();
            DummyInputs.(flsToggles) = true;

            % WHEN we check if FLS loads are required
            actual = usain.loads.Loads.check_is_required_fls(DummyInputs);

            % THEN
            Obj.verifyTrue(actual);

            % WHEN that one active FLS toggle is also disabled
            DummyInputs.(flsToggles) = false;
            actual = usain.loads.Loads.check_is_required_fls(DummyInputs);

            % THEN
            Obj.verifyFalse(actual);
        end

        function check_is_required_uls__one_uls_condition_active(Obj, ulsToggles)
            % GIVEN the parametrized inputs assigned to a struct, such that it
            % reflects USAIN inputs where one ULS condition is active
            DummyInputs = Obj.create_or_update_input_struct_with_all_conditions_disabled();
            DummyInputs.(ulsToggles) = true;

            % WHEN we check if ULS loads are required
            actual = usain.loads.Loads.check_is_required_uls(DummyInputs);

            % THEN
            Obj.verifyTrue(actual);

            % WHEN that one active ULS toggle is also disabled
            DummyInputs.(ulsToggles) = false;
            actual = usain.loads.Loads.check_is_required_uls(DummyInputs);

            % THEN
            Obj.verifyFalse(actual);
        end

        function check_is_required_s1__one_s1_condition_active(Obj, s1Toggles)
            % GIVEN the parametrized inputs assigned to a struct, such that it reflects USAIN inputs where one SLS
            % condition is active
            Inputs = Obj.create_or_update_input_struct_with_all_conditions_disabled();
            Inputs.(s1Toggles) = true;

            % WHEN we check if S1 loads are required
            actual = usain.loads.Loads.check_is_required_s1(Inputs);

            % THEN
            Obj.verifyTrue(actual);

            % WHEN that one active FLS toggle is also disabled
            Inputs.(s1Toggles) = false;
            actual = usain.loads.Loads.check_is_required_s1(Inputs);

            % THEN
            Obj.verifyFalse(actual);
        end

    end

    methods (Static)

        function Inputs = create_or_update_input_struct_with_all_conditions_disabled(varargin)
            if nargin == 1
                Inputs = varargin{:};
            end

            conditInputs = UsainUtils.ICondition.CONDITION_CLASS_NAMES(:)';
            for condit = conditInputs(:)'
                Inputs.(condit{1}) = false;
            end
        end

    end
end
