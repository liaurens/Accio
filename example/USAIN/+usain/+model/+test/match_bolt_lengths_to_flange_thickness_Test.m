classdef match_bolt_lengths_to_flange_thickness_Test < Unittest.TestCase  % mh:ignore_style

    methods (Test, TestTags = {'unit'})

        function match_bolt_lengths_to_flange_thickness__success(Obj)
            % GIVEN a DesignSpace instance specifically setup for the matching calculations
            thickness = 1e-3 * [100, 100, 105, 115, 150, 220]';
            boltIds = ones(length(thickness), 1);
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture()).data;

            % WHEN both the bolt length and extender length are not set by the user
            Inputs.site = usain.inputs.Site.OFFSHORE;
            Inputs.boltOptions = {'ISO_M42'};
            Inputs.lengthBoltExtender = nan;
            [actualBoltLength, actualExtenderLength] = usain.model.match_bolt_lengths_to_flange_thickness( ...
                Inputs, thickness, boltIds);

            % THEN expect the given bolt and extender lengths
            % - the first and second lengths are the same because the flange thickness is the same as well
            % - the last entries are NaN because no bolt+extender length could be matched
            % - 0mm extenders because we have long thread length (typical for ISO studs)
            expectedBoltLength = 1e-3 * [360, 360, 370, 390, 460, nan]';
            expectedExtenderLength = 1e-3 * [0, 0, 0, 0, 0, nan]';
            Obj.assertEqual(actualBoltLength, expectedBoltLength, 'AbsTol', 1e-4);
            Obj.assertEqual(actualExtenderLength, expectedExtenderLength, 'AbsTol', 1e-4);
        end

        function match_bolt_lengths_to_flange_thickness__fixed_bolt_length(Obj)
            % GIVEN a DesignSpace instance specifically setup for the matching calculations
            thickness = 1e-3 * [100, 100, 105, 115, 150]';
            boltIds = ones(length(thickness), 1);
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture()).data;

            % WHEN the bolt length is user-defined and the extender length is not
            Inputs.site = usain.inputs.Site.OFFSHORE;
            Inputs.boltOptions = {'ISO_M42x400x110'}; % Smaller thread length -> increases need for an extender
            Inputs.lengthBoltExtender = nan;
            Inputs.TOL_EXTENDER_LENGTH = 0.001;
            [actualBoltLength, actualExtenderLength] = usain.model.match_bolt_lengths_to_flange_thickness( ...
                Inputs, thickness, boltIds);

            % THEN expect all non-nan bolt lengths to be the same
            expectedBoltLength = 1e-3 * [400, 400, 400, 400, nan]';
            expectedExtenderLength = 1e-3 * [23, 23, 13, 0, nan]';
            Obj.assertEqual(actualBoltLength, expectedBoltLength, 'AbsTol', 1e-4);
            Obj.assertEqual(actualExtenderLength, expectedExtenderLength, 'AbsTol', 1e-4);
        end

        function match_bolt_lengths_to_flange_thickness__fixed_extender_length(Obj)
            % GIVEN a DesignSpace instance specifically setup for the matching calculations
            thickness = 1e-3 * [100, 115, 150, 200]';
            boltIds = ones(length(thickness), 1);
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture()).data;

            % WHEN the extender length is user-defined and the bolt length is not
            Inputs.site = usain.inputs.Site.OFFSHORE;
            Inputs.boltOptions = {'ISO_M42'};
            Inputs.lengthBoltExtender = 0.040;
            [actualBoltLength, actualExtenderLength] = usain.model.match_bolt_lengths_to_flange_thickness( ...
                Inputs, thickness, boltIds);

            % THEN expect all non-nan bolt extender lengths to be the same
            expectedBoltLength = 1e-3 * [400, 430, 500, nan]';
            expectedExtenderLength = 1e-3 * [40 40, 40, nan]';
            Obj.assertEqual(actualBoltLength, expectedBoltLength, 'AbsTol', 1e-4);
            Obj.assertEqual(actualExtenderLength, expectedExtenderLength, 'AbsTol', 1e-4);
        end

        function match_bolt_lengths_to_flange_thickness__fixed_bolt_n_ext_length(Obj)
            % GIVEN a DesignSpace instance specifically setup for the matching calculations
            thickness = 1e-3 * [100, 102, 105, 150]';
            boltIds = ones(length(thickness), 1);
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture()).data;

            % WHEN both the bolt and extender lengths are user-defined
            Inputs.site = usain.inputs.Site.OFFSHORE;
            Inputs.boltOptions = {'ISO_M42x400'};
            Inputs.lengthBoltExtender = 0.040;
            [actualBoltLength, actualExtenderLength] = usain.model.match_bolt_lengths_to_flange_thickness( ...
                Inputs, thickness, boltIds);

            % THEN expect all non-nan bolt lengths to be the same
            expectedBoltLength = 1e-3 * [400, 400, nan, nan]';
            expectedExtenderLength = 1e-3 * [40, 40, nan, nan]';
            Obj.assertEqual(actualBoltLength, expectedBoltLength, 'AbsTol', 1e-4);
            Obj.assertEqual(actualExtenderLength, expectedExtenderLength, 'AbsTol', 1e-4);
        end

        function match_bolt_lengths_to_flange_thickness__hv__success(Obj)
            % GIVEN a DesignSpace instance specifically setup for the matching calculations of HV bolts
            thickness = 1e-3 * [100, 105, 110, 115, 120, 125, 130]';
            boltIds = ones(length(thickness), 1);
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture()).data;

            % WHEN both the bolt and extender lengths are user-defined
            Inputs.site = usain.inputs.Site.OFFSHORE;
            Inputs.boltOptions = {'HV_M42'};
            Inputs.lengthBoltExtender = nan;
            Inputs.tighteningMethod = {'torque'};
            Inputs.NUT_TYPE = {'HV'};
            [actualBoltLength, actualExtenderLength] = usain.model.match_bolt_lengths_to_flange_thickness( ...
                Inputs, thickness, boltIds);

            % THEN expect
            expectedBoltLength = 1e-3 * [270, 280, 290, 300, 310, 320, 330]';
            expectedExtenderLength = zeros(length(thickness), 1);
            Obj.assertEqual(actualBoltLength, expectedBoltLength, 'AbsTol', 1e-4);
            Obj.assertEqual(actualExtenderLength, expectedExtenderLength, 'AbsTol', 1e-4);
        end

        function match_bolt_lengths_to_flange_thickness__hv_fix_bolt_length(Obj)
            % GIVEN a DesignSpace instance specifically setup for the matching calculations of HV bolts
            thickness = 1e-3 * [100, 105, 110, 115, 120, 125, 130]';
            boltIds = ones(length(thickness), 1);
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture()).data;

            % WHEN the bolt length is user-defined and extender length not
            Inputs.site = usain.inputs.Site.OFFSHORE;
            Inputs.boltOptions = {'HV_M42x300'};
            Inputs.lengthBoltExtender = nan;
            Inputs.tighteningMethod = {'torque'};
            Inputs.NUT_TYPE = {'HV'};
            [actualBoltLength, actualExtenderLength] = usain.model.match_bolt_lengths_to_flange_thickness( ...
                Inputs, thickness, boltIds);

            % THEN expect
            expectedBoltLength = 1e-3 * [300, 300, 300, 300, nan, nan, nan]';
            expectedExtenderLength = 1e-3 * [30, 20, 10, 0, nan, nan, nan]';
            Obj.assertEqual(actualBoltLength, expectedBoltLength, 'AbsTol', 1e-4);
            Obj.assertEqual(actualExtenderLength, expectedExtenderLength, 'AbsTol', 1e-4);
        end

        function match_bolt_lengths_to_flange_thickness__hv_fix_extender_length(Obj)
            % GIVEN a DesignSpace instance specifically setup for the matching calculations of HV bolts
            thickness = 1e-3 * [100, 105, 110, 115, 120, 125, 130]';
            boltIds = ones(length(thickness), 1);
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture()).data;

            % WHEN the extender length is user-defined and bolt length not
            Inputs.site = usain.inputs.Site.OFFSHORE;
            Inputs.boltOptions = {'HV_M42'};
            Inputs.lengthBoltExtender = 0.020;
            Inputs.tighteningMethod = {'torque'};
            Inputs.NUT_TYPE = {'HV'};
            [actualBoltLength, actualExtenderLength] = usain.model.match_bolt_lengths_to_flange_thickness( ...
                Inputs, thickness, boltIds);

            % THEN expect
            expectedBoltLength = 1e-3 * [290, 300, 310, 320, 330, 340, nan]';
            expectedExtenderLength = 1e-3 * [20, 20, 20, 20, 20, 20, nan]';
            Obj.assertEqual(actualBoltLength, expectedBoltLength, 'AbsTol', 1e-4);
            Obj.assertEqual(actualExtenderLength, expectedExtenderLength, 'AbsTol', 1e-4);
        end

        function match_bolt_lengths_to_flange_thickness__hv_fix_bolt_n_ext_lengt(Obj)
            % GIVEN a DesignSpace instance specifically setup for the matching calculations of HV bolts
            thickness = 1e-3 * [100, 105, 110, 115, 120, 125, 130]';
            boltIds = ones(length(thickness), 1);
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture()).data;

            % WHEN both the bolt and extender lengths are user-defined
            Inputs.site = usain.inputs.Site.OFFSHORE;
            Inputs.boltOptions = {'HV_M42x300'};
            Inputs.lengthBoltExtender = 0.020;
            Inputs.tighteningMethod = {'torque'};
            Inputs.NUT_TYPE = {'HV'};
            [actualBoltLength, actualExtenderLength] = usain.model.match_bolt_lengths_to_flange_thickness( ...
                Inputs, thickness, boltIds);

            % THEN expect
            expectedBoltLength = 1e-3 * [nan, 300, nan, nan, nan, nan, nan]';
            expectedExtenderLength = 1e-3 * [nan, 20, nan, nan, nan, nan, nan]';
            Obj.assertEqual(actualBoltLength, expectedBoltLength, 'AbsTol', 1e-4);
            Obj.assertEqual(actualExtenderLength, expectedExtenderLength, 'AbsTol', 1e-4);
        end

    end
end
