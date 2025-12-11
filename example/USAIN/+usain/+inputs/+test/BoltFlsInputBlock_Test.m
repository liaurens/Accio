classdef (SharedTestFixtures = {fixtures.SilentlyLogFixture(logging.Level.WARNING)}) ...
    BoltFlsInputBlock_Test < Unittest.TestCase

    methods (Test, TestTags = {'unit'})

        function convert_to_string__happy(Obj)
            % GIVEN BoltFls inputs in "non-manipulated inputs InputFile data format"
            BoltFls = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 2)).data.BoltFls;
            % NOTE: Use the `ManipulatedInputsFixture` fixture, but "reverse-process" the data such that it is
            % representing the non-manipulated data format, instead of the format after post-parse manipulations.
            BoltFls.BOLT_FORCE_MODEL = {'sgre2', 'schmidtneuper'};
            BoltFls.SN_CURVE_BOLT = {'', 'EC3_DC123'};

            BoltFlsInputs = usain.inputs.BoltFlsInputBlock(BoltFls);
            Actual = BoltFlsInputs.convert_to_string(BoltFls);

            Obj.verifyEqual(Actual.BOLT_FORCE_MODEL, ["sgre2", "schmidtneuper"]);
            Obj.verifyEqual(Actual.SN_CURVE_BOLT, ["", "EC3_DC123"]);
        end

        function assign_default_thickness_exponent__happy(Obj)
            % GIVEN inputs for both sgre2 and a non-sgre2 model, without a user-defined exponent
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 2)).data;
            Inputs.BoltFls.BOLT_FORCE_MODEL = ["schmidtneuper", "sgre2"];
            Inputs.BoltFls.THICKNESS_EXPONENT_BOLT = [nan, nan];

            % WHEN
            % THEN expect only the non-sgre2 exponent replaced
            BoltFlsInputs = usain.inputs.BoltFlsInputBlock(Inputs.BoltFls);
            Actual = BoltFlsInputs.assign_default_thickness_exponent(Inputs.BoltFls);
            Obj.verifyEqual(Actual.THICKNESS_EXPONENT_BOLT, [0.25, nan]);
            % ... and expect no warnings logged
            Obj.verifyEmpty(BoltFlsInputs.LogHandler.buffer);

            % WHEN mimicking a user-defined exponent
            % THEN
            Inputs.BoltFls.THICKNESS_EXPONENT_BOLT = [1.23, 2.34];
            BoltFlsInputs = usain.inputs.BoltFlsInputBlock(Inputs.BoltFls);
            Actual = BoltFlsInputs.assign_default_thickness_exponent(Inputs.BoltFls);
            Obj.verifyEqual(Actual.THICKNESS_EXPONENT_BOLT, [1.23, 2.34]);

            % ... and expect warning(s) logged
            Obj.assertNotEmpty(BoltFlsInputs.LogHandler.buffer);
            Obj.verifyEqual(BoltFlsInputs.LogHandler.buffer{1}.message, ...
                'Non-default value for input "THICKNESS_EXPONENT_BOLT(1)" will be used: 1.23');
            Obj.verifyEqual(BoltFlsInputs.LogHandler.buffer{2}.message, ...
                'Non-default value for input "THICKNESS_EXPONENT_BOLT(2)" will be used: 2.34');
        end

        function assign_default_psf__happy(Obj)
            % GIVEN inputs for both sgre2 and a non-sgre2 model, without a user-defined exponent
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 2)).data;
            Inputs.BoltFls.BOLT_FORCE_MODEL = ["schmidtneuper", "sgre2"];
            Inputs.BoltFls.PSF_BOLT_MATERIAL_FLS = [nan, nan];

            % WHEN
            % THEN expect only the non-sgre2 exponent replaced
            BoltFlsInputs = usain.inputs.BoltFlsInputBlock(Inputs.BoltFls);
            Actual = BoltFlsInputs.assign_default_psf(Inputs.BoltFls);
            Obj.verifyEqual(Actual.PSF_BOLT_MATERIAL_FLS, [1.25, 1.10]);
            % ... and expect no warnings logged
            Obj.verifyEmpty(BoltFlsInputs.LogHandler.buffer);

            % WHEN mimicking a user-defined exponent
            % THEN
            Inputs.BoltFls.PSF_BOLT_MATERIAL_FLS = [1.23, 2.34];
            BoltFlsInputs = usain.inputs.BoltFlsInputBlock(Inputs.BoltFls);
            Actual = BoltFlsInputs.assign_default_psf(Inputs.BoltFls);
            Obj.verifyEqual(Actual.PSF_BOLT_MATERIAL_FLS, [1.23, 2.34]);

            % ... and expect warning(s) logged
            Obj.assertNotEmpty(BoltFlsInputs.LogHandler.buffer);
            Obj.verifyEqual(BoltFlsInputs.LogHandler.buffer{1}.message, ...
                'Non-default value for input "PSF_BOLT_MATERIAL_FLS(1)" will be used: 1.23');
            Obj.verifyEqual(BoltFlsInputs.LogHandler.buffer{2}.message, ...
                'Non-default value for input "PSF_BOLT_MATERIAL_FLS(2)" will be used: 2.34');
        end

        function assign_default_sn_curve__happy(Obj)
            % GIVEN inputs for both sgre2 and a non-sgre2 model, without a user-defined exponent
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 2)).data;
            Inputs.BoltFls.BOLT_FORCE_MODEL = ["schmidtneuper", "sgre2"];
            Inputs.BoltFls.SN_CURVE_BOLT = ["", ""];

            % WHEN
            % THEN expect only the non-sgre2 exponent replaced
            BoltFlsInputs = usain.inputs.BoltFlsInputBlock(Inputs.BoltFls);
            Actual = BoltFlsInputs.assign_default_sn_curve(Inputs.BoltFls);
            Obj.verifyEqual(Actual.SN_CURVE_BOLT, ["EC3_DC36*", "EC3_DC50"]);
            % ... and expect no warnings logged
            Obj.verifyEmpty(BoltFlsInputs.LogHandler.buffer);

            % WHEN mimicking a user-defined exponent
            % THEN
            Inputs.BoltFls.SN_CURVE_BOLT = ["foo", "bar"];
            BoltFlsInputs = usain.inputs.BoltFlsInputBlock(Inputs.BoltFls);
            Actual = BoltFlsInputs.assign_default_sn_curve(Inputs.BoltFls);
            Obj.verifyEqual(Actual.SN_CURVE_BOLT, ["foo", "bar"]);

            % ... and expect warning(s) logged
            Obj.assertNotEmpty(BoltFlsInputs.LogHandler.buffer);
            Obj.verifyEqual(BoltFlsInputs.LogHandler.buffer{1}.message, ...
                'Non-default value for input "SN_CURVE_BOLT(1)" will be used: foo');
            Obj.verifyEqual(BoltFlsInputs.LogHandler.buffer{2}.message, ...
                'Non-default value for input "SN_CURVE_BOLT(2)" will be used: bar');
        end

        function log_nondefault__no_warning(Obj)
            % GIVEN
            BoltFlsInputs = usain.inputs.BoltFlsInputBlock(struct());

            % WHEN given args such that no warning is logged
            BoltFlsInputs.log_nondefault(false, "foo", "bar");
            BoltFlsInputs.log_nondefault([false, false], "foo", ["bar", "baz"]);

            % THEN
            Obj.verifyEmpty(BoltFlsInputs.LogHandler.buffer);
        end

        function log_nondefault__warning_logged(Obj)
            % GIVEN
            BoltFlsInputs = usain.inputs.BoltFlsInputBlock(struct());

            % WHEN given args such that a warning is logged
            BoltFlsInputs.log_nondefault([false, true], "foo", ["bar", "baz"]);

            % THEN
            Obj.assertNotEmpty(BoltFlsInputs.LogHandler.buffer);
            Obj.verifyEqual(BoltFlsInputs.LogHandler.buffer{1}.message, ...
                'Non-default value for input "foo(2)" will be used: baz');
        end

    end

    methods (Test, TestTags = {'integation'})

        function process_input_block__array_operations(Obj)
            % GIVEN inputs for single and for multiple input blocks
            SingleInputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 1)).data;
            MultiInputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 2)).data;

            % WHEN assigning defaults
            % THEN expect no errors
            usain.inputs.BoltFlsInputBlock(SingleInputs.BoltFls).process_input_block();
            usain.inputs.BoltFlsInputBlock(MultiInputs.BoltFls).process_input_block();
        end

    end

end
