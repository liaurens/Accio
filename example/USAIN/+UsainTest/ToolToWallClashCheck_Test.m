classdef ToolToWallClashCheck_Test < UsainTest.UsainTestCase & matlab.mock.TestCase

    methods (Test, TestTags = {'unit'})

        function calc_max_allowable_bcd__happy(Obj)
            % GIVEN a mock where setup_inner_diameter_interpolant always returns the same, making method
            % calc_max_allowable_bcd independent of StructuralModel data
            [Stub, Behavior] = Obj.createMock(?UsainUtils.ToolToWallClashCheck);
            Obj.assignOutputsWhen(withExactInputs(Behavior.setup_inner_diameter_interpolant()), @(x) 8.0);
            Stub.Mdl = UsainUtils.SelectedModel();
            Stub.Mdl.Tool.dimHeight = 0;
            Stub.Mdl.Tool.dimRadialDir = 0.05;
            Stub.Mdl.Inputs.TIGHTENING_SIDE_INSTALLATION = {'upper'};
            Stub.Mdl.Tool.tighteningMethod = {'tension'};
            Stub.Mdl.Inputs.zFlange = 0;
            Stub.Mdl.Inputs.TOL_BCD_TOOL_WALL = 0.004;
            Stub.Mdl.Inputs.diamBoltHole = 0.080;
            Stub.Mdl.Bolt.diam = 0.070;
            Stub.Mdl.Space.thickness = 0.200;

            % WHEN, THEN
            actual = Stub.calc_max_allowable_bcd();
            expected = 7.886;
            Obj.assertEqual(actual, expected, 'AbsTol', 1e-5);
        end

        function report_results__happy(Obj)
            % GIVEN a mock UsainUtils.ToolToWallClashCheck object whose calc_max_allowable_bcd() method calls
            % always return 1234
            [Stub, Behavior] = Obj.createMock(?UsainUtils.ToolToWallClashCheck);
            Obj.assignOutputsWhen(withExactInputs(Behavior.calc_max_allowable_bcd()), 1234);

            % WHEN the chosen BCD is exactly 1234
            % THEN expect no warning
            Stub.Mdl = UsainUtils.SelectedModel();
            Stub.Mdl.Inputs.diamBoltCircle = 1234;
            Obj.verify_no_warning_logged(@() Stub.report_results());

            % WHEN the chosen BCD is smaller than 1234
            % THEN expect no warning
            Stub.Mdl.Inputs.diamBoltCircle = 1230;
            Obj.verify_no_warning_logged(@() Stub.report_results());
        end

        function report_results__bcd_exceeds_max_allowed(Obj)
            % GIVEN a mock UsainUtils.ToolToWallClashCheck object whose calc_max_allowable_bcd() method calls
            % always return 1234
            [Stub, Behavior] = Obj.createMock(?UsainUtils.ToolToWallClashCheck);
            Obj.assignOutputsWhen(withExactInputs(Behavior.calc_max_allowable_bcd()), 1234);

            % WHEN the chosen BCD is > 1234
            % THEN
            Stub.Mdl = UsainUtils.SelectedModel();
            Stub.Mdl.Inputs.diamBoltCircle = 1235;
            expected = 'USAIN:ToolToWallClashCheck:ClashDetected';
            Obj.verify_warning_logged(@() Stub.report_results(), expected);
        end

        function report_results__nan_bcd(Obj)
            % GIVEN a mock UsainUtils.ToolToWallClashCheck object whose calc_max_allowable_bcd() method calls
            % always return NaN
            [Stub, Behavior] = Obj.createMock(?UsainUtils.ToolToWallClashCheck);
            Obj.assignOutputsWhen(withExactInputs(Behavior.calc_max_allowable_bcd()), NaN);

            % WHEN, THEN
            Stub.Mdl = UsainUtils.SelectedModel();
            Stub.Mdl.Inputs.diamBoltCircle = 1234;
            Stub.Mdl.Tool.dimHeight = 0.123;
            Stub.Mdl.Inputs.TIGHTENING_SIDE_INSTALLATION  = 'upper';
            expected = 'USAIN:ToolToWallClashCheck:ClashNotChecked';
            Obj.verify_warning_logged(@() Stub.report_results(), expected);
        end

        function from_flange_model__happy(Obj)
            % GIVEN, WHEN, THEN
            FlangeModel = UsainUtils.SelectedModel();
            actual = UsainUtils.ToolToWallClashCheck.from_flange_model(FlangeModel);
            Obj.assertInstanceOf(actual, 'UsainUtils.ToolToWallClashCheck');
        end

        function from_flange_model__not_a_selectedmodel_class(Obj)
            % GIVEN, WHEN, THEN
            FlangeModel = UsainUtils.FlangeModel();
            f = @() UsainUtils.ToolToWallClashCheck.from_flange_model(FlangeModel);
            Obj.assertError(f, 'USAIN:ToolToWallClashCheck:NotASelectedModel');
        end

        function post_parse_checks__torque_and_no_strmdl(Obj)
            % GIVEN
            site = usain.inputs.Site.OFFSHORE;
            boltOptions = {'ISO_M42'};
            tighteningMethod = {'torque'};
            nutType = 'ISO';
            structureInpFilePath = '';

            % WHEN
            msg = UsainUtils.ToolToWallClashCheck.post_parse_checks( ...
                site, boltOptions, tighteningMethod, nutType, structureInpFilePath);

            % THEN we expect an empty message because torque tools have a zero height, so this check is not
            % relevant (and hence a warning message would be overkill)
            Obj.assertEmpty(msg);
        end

        function post_parse_checks__tension_and_strmdl(Obj)
            % GIVEN
            site = usain.inputs.Site.OFFSHORE;
            boltOptions = {'ISO_M42', 'ISO_M42x380'};
            tighteningMethod = {'tension', 'tension'};
            nutType = {'ISR', 'ISR'};
            structureInpFilePath = 'path/to/a/mdl';

            % WHEN
            msg = UsainUtils.ToolToWallClashCheck.post_parse_checks( ...
                site, boltOptions, tighteningMethod, nutType, structureInpFilePath);

            % THEN we expect an empty message because a StructuralModel path is provided
            Obj.assertEmpty(msg);
        end

        function post_parse_checks__torque_and_strmdl(Obj)
            % GIVEN
            site = usain.inputs.Site.OFFSHORE;
            boltOptions = {'ISO_M42', 'ISO_M42x380'};
            tighteningMethod = {'torque', 'torque'};
            nutType = {'ISO', 'ISO'};
            structureInpFilePath = 'path/to/a/mdl';

            % WHEN
            msg = UsainUtils.ToolToWallClashCheck.post_parse_checks( ...
                site, boltOptions, tighteningMethod, nutType, structureInpFilePath);

            % THEN we expect an empty messsage because a StructuralModel path is provided
            Obj.assertEmpty(msg);
        end

        function post_parse_checks__tension_and_no_strmdl(Obj)
            % GIVEN
            site = usain.inputs.Site.OFFSHORE;
            boltOptions = {'ISO_M42', 'ISO_M42x380'};
            tighteningMethod = {'tension', 'tension'};
            nutType = {'ISR', 'ISR'};
            structureInpFilePath = '';

            % WHEN
            msg = UsainUtils.ToolToWallClashCheck.post_parse_checks( ...
                site, boltOptions, tighteningMethod, nutType, structureInpFilePath);

            % THEN we expect a message because no StructuralModel path is provided for tension tools (nonzero
            % height)
            Obj.assertNotEmpty(msg);
            Obj.assertSubstring(msg, 'StructuralModel is required for clash check');

            % WHEN we change one but not all tools to 'torque'
            % THEN we expect the same
            tighteningMethod = {'tension', 'torque'};
            nutType = {'ISR', 'ISO'};
            msg = UsainUtils.ToolToWallClashCheck.post_parse_checks( ...
                site, boltOptions, tighteningMethod, nutType, structureInpFilePath);
            Obj.assertNotEmpty(msg);
            Obj.assertSubstring(msg, 'StructuralModel is required for clash check');
        end

        function post_load_checks__skip_for_torque(Obj)
            % GIVEN
            site = usain.inputs.Site.OFFSHORE;
            boltOptions = {'ISO_M72', 'ISO_M42x380'};
            tighteningMethod = {'torque', 'torque'};
            tighteningSide = {'upper', 'upper'};
            nutType = {'ISO', 'ISO'};
            zFlange = -10;
            structuralModelZRange = [-10, 100];

            % WHEN
            msg = UsainUtils.ToolToWallClashCheck.post_load_checks( ...
                site, boltOptions, tighteningMethod, tighteningSide, nutType, zFlange, structuralModelZRange);

            % THEN we expect no message because this check is skipped for torque tools (tool with zero height)
            Obj.assertEmpty(msg);
        end

        function post_load_checks__zflange_not_at_structure_end(Obj)
            % GIVEN
            site = usain.inputs.Site.OFFSHORE;
            boltOptions = {'ISO_M72'};
            tighteningMethod = {'tension'};
            tighteningSide = {'upper'};
            nutType = {'ISR'};
            zFlange = 50;
            structuralModelZRange = [-10, 100];

            % WHEN
            msg = UsainUtils.ToolToWallClashCheck.post_load_checks( ...
                site, boltOptions, tighteningMethod, tighteningSide, nutType, zFlange, structuralModelZRange);

            % THEN we expect no message because zFlange is well within the structure z bounds
            Obj.assertEmpty(msg);
        end

        function post_load_checks__zflange_at_structure_end(Obj)
            % GIVEN
            site = usain.inputs.Site.OFFSHORE;
            boltOptions = {'ISO_M72'};
            tighteningMethod = {'tension'};
            tighteningSide = {'upper'};
            nutType = {'ISR'};
            zFlange = -10;
            structuralModelZRange = [-10, 100];

            % WHEN
            msg = UsainUtils.ToolToWallClashCheck.post_load_checks( ...
                site, boltOptions, tighteningMethod, tighteningSide, nutType, zFlange, structuralModelZRange);

            % THEN we expect a message because zFlange is at the bottom of the structure z bounds
            Obj.assertNotEmpty(msg);
            Obj.assertSubstring(msg, 'Cannot check for clash of tension tools and structure wall');
        end

    end

end
