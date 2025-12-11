classdef FatigueLimitStateWithSgre2_0_Test < UsainTest.UsainTestCase  % mh:ignore_style

    methods (Test, TestTags = {'unit'})

        function get_description__happy(Obj)
            % GIVEN
            Condition = usain.sgre2.FatigueLimitStateWithSgre2_0(99, 2);
            Condition.Mdl.Inputs.SGRE2.GAP_ANGLE = deg2rad([30, 60]);

            % WHEN, THEN
            Obj.verifyEqual(Condition.description, "Fatigue limit state (set #99, 60 deg)");
        end

        function setup_sn_curve__expected(Obj)
            % GIVEN A FatigueLimitStateWithSgre2_0 with dummy but representative inputs for the S-N curve
            Condition = usain.sgre2.FatigueLimitStateWithSgre2_0(1, 1);
            Condition.Mdl = UsainUtils.SelectedModel();
            Condition.Mdl.Inputs.BoltFls.SN_CURVE_BOLT = "EC3_DC50";
            Condition.Mdl.Inputs.BoltFls.THICKNESS_EXPONENT_BOLT = 0.1;

            % WHEN, THEN
            Actual = Condition.setup_sn_curve();
            Obj.verifyEqual(Actual.nKnee, 2e6);
            Obj.verifyEqual(Actual.sDetail, 50);
            Obj.verifyEqual(Actual.tExp, 0.1);
        end

        function calc_bending_contribution__input_set(Obj)
            % GIVEN A FatigueLimitStateWithSgre2_0 instance
            DummyBoltModel = usain.sgre2.BoltLoadModel();
            Condition = usain.sgre2.FatigueLimitStateWithSgre2_0(1, 1);
            Condition.Mdl = UsainUtils.SelectedModel();

            % WHEN the expert input is set
            expected = 0.1234;
            Condition.Mdl.Inputs.SGRE2.BENDING_CONTRIBUTION = expected;

            % THEN expect this value to be returned
            actual = Condition.calc_bending_contribution();
            Obj.verifyEqual(actual, expected);
        end

        function calc_bending_contribution__input_not_set(Obj)
            % GIVEN A FatigueLimitStateWithSgre2_0 instance
            DummyBoltModel = usain.sgre2.BoltLoadModel();
            Condition = usain.sgre2.FatigueLimitStateWithSgre2_0(1, 1);
            Condition.Mdl = UsainUtils.SelectedModel();
            Condition.Mdl.Bolt.diam = 64e-3;

            % WHEN the expert input is not set
            Condition.Mdl.Inputs.SGRE2.BENDING_CONTRIBUTION = nan;

            % THEN expect this value to be returned
            actual = Condition.calc_bending_contribution();
            Obj.verifyEqual(actual, 0.7016, 'AbsTol', 1e-4);

            % WHEN changing the bolt diameter to a very low value
            % THEN expect a minimum bending contribution of 0.5
            Condition.Mdl.Bolt.diam = 36e-3;
            Obj.verifyEqual(Condition.calc_bending_contribution(), 0.5);
            Condition.Mdl.Bolt.diam = 10e-3;
            Obj.verifyEqual(Condition.calc_bending_contribution(), 0.5);

            % WHEN changing the bolt diameter to 150mm (upper bound)
            % THEN expect a maximum bending contribution of 1.0
            Condition.Mdl.Bolt.diam = 150e-3;
            Obj.verifyEqual(Condition.calc_bending_contribution(), 1.0);
        end

        function calc_size_effect__input_set(Obj)
            % GIVEN A FatigueLimitStateWithSgre2_0 and the THICKNESS_EXPONENT_BOLT input set
            DummyBoltModel = usain.sgre2.BoltLoadModel();
            Condition = usain.sgre2.FatigueLimitStateWithSgre2_0(1, 1);
            Condition.Mdl = UsainUtils.SelectedModel();
            Condition.Mdl.Bolt.diam = 100e-3;
            Condition.Mdl.Inputs.BoltFls.THICKNESS_EXPONENT_BOLT = 0.123;

            % WHEN setting up the S-N curve and computing the size effect
            Condition.SnCurve = sn_curve.SnCurve.setup_curve_eurocode( ...
                'label', 'foo', ...
                'sDetail', 50, ...
                'tRef', 30e-3, ...
                'tExp', Condition.Mdl.Inputs.BoltFls.THICKNESS_EXPONENT_BOLT);
            actual = Condition.calc_size_effect();

            % THEN
            expected = 1.1596;  % (100/30)^0.123
            Obj.verifyEqual(actual, expected, 'AbsTol', 1e-4);
        end

        function calc_size_effect__input_not_set(Obj)
            % GIVEN A FatigueLimitStateWithSgre2_0 and the THICKNESS_EXPONENT_BOLT input not set
            DummyBoltModel = usain.sgre2.BoltLoadModel();
            Condition = usain.sgre2.FatigueLimitStateWithSgre2_0(1, 1);
            Condition.Mdl = UsainUtils.SelectedModel();
            Condition.Mdl.Bolt.diam = 100e-3;
            Condition.Mdl.Inputs.BoltFls.THICKNESS_EXPONENT_BOLT = nan;

            % WHEN setting up the S-N curve and computing the size effect
            Condition.SnCurve = sn_curve.SnCurve.setup_curve_eurocode( ...
                'label', 'foo', ...
                'sDetail', 50, ...
                'tRef', 30e-3, ...
                'tExp', Condition.Mdl.Inputs.BoltFls.THICKNESS_EXPONENT_BOLT);
            actual = Condition.calc_size_effect();

            % THEN
            expected = 1.2245;  % (100/30)^0.10 * (100/72)^0.25
            Obj.verifyEqual(actual, expected, 'AbsTol', 1e-4);

            % ... and for a bolt diameter <M72 (i.e. no penalty)
            Condition.Mdl.Bolt.diam = 64e-3;
            expected = 1.0787;  % (64/30)^0.10
            Obj.verifyEqual(Condition.calc_size_effect(), expected, 'AbsTol', 1e-4);
        end

    end
end
