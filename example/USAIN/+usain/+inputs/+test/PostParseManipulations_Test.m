classdef PostParseManipulations_Test < Unittest.TestCase

    methods (Test, TestTags = {'unit'})

        function replace_run_name_whitespaces__happy(Obj)
            % GIVEN
            Inputs.runName = 'Some run name with white spaces';
            Manipulator = usain.inputs.PostParseManipulations(Inputs = Inputs);

            % WHEN, THEN
            Manipulator.replace_run_name_whitespaces();
            Obj.verifyEqual(Manipulator.Inputs.runName, 'Some_run_name_with_white_spaces');
        end

        function assign_conditional_input_defaults__happy(Obj)
            % GIVEN Inputs which would set all defaults for the conditional inputs
            Inputs.lengthBoltExtender = nan;
            Inputs.E_BOLT = nan;
            Inputs.E_FLANGE = nan;
            Inputs.FLANGE_STEEL_TYPE = '';
            Inputs.PSF_BOLT_RESISTANCE_JPN = nan;
            Inputs.PSF_BOLT_RESISTANCE_JPN_TAG = '';
            Inputs.DO_ASSESS_ULS = nan;
            Inputs.DO_ASSESS_ULS_JPN = nan;
            Inputs.countryCode = 'ROW';
            Inputs.BoltFls.SN_CURVE_BOLT = '';
            Inputs.BoltFls.BOLT_FORCE_MODEL = 'sgre2';
            Inputs.BoltFls.THICKNESS_EXPONENT_BOLT = nan;
            Inputs.BoltFls.PSF_BOLT_MATERIAL_FLS = nan;
            Manipulator = usain.inputs.PostParseManipulations(Inputs = Inputs);

            % WHEN, THEN expect that it simply runs to completion, individual submethods are tested separately.
            Manipulator.assign_conditional_input_defaults();
        end

        function assign_default_bolt_extender_length__happy(Obj)
            % GIVEN Inputs such that default would be assigned, first ROW.
            Inputs.lengthBoltExtender = nan;
            Inputs.countryCode = 'ROW';
            Manipulator = usain.inputs.PostParseManipulations(Inputs = Inputs);

            % WHEN THEN expect for ROW still nan
            Manipulator.assign_default_bolt_extender_length();
            Obj.verifyEqual(Manipulator.Inputs.lengthBoltExtender, nan);

            % NEXT GIVEN JPN
            Inputs.lengthBoltExtender = nan;
            Inputs.countryCode = 'JPN';
            Manipulator = usain.inputs.PostParseManipulations(Inputs = Inputs);

            % WHEN THEN expect for JPN a value of zero
            Manipulator.assign_default_bolt_extender_length();
            Obj.verifyEqual(Manipulator.Inputs.lengthBoltExtender, 0.0);

            % NEXT GIVIN Inputs such that the default is not assigned
            Inputs.lengthBoltExtender = 123;
            Inputs.countryCode = 'ROW';
            Manipulator = usain.inputs.PostParseManipulations(Inputs = Inputs);

            % WHEN THEN expect that the value is the same as the original input.
            Manipulator.assign_default_bolt_extender_length();
            Obj.verifyEqual(Manipulator.Inputs.lengthBoltExtender, 123);
        end

        function assign_default_bolt_youngs_modulus__happy(Obj)
            % GIVEN Inputs such that default would be assigned, first ROW.
            Inputs.E_BOLT = nan;
            Inputs.countryCode = 'ROW';
            Manipulator = usain.inputs.PostParseManipulations(Inputs = Inputs);

            % WHEN THEN expect for ROW
            Manipulator.assign_default_bolt_youngs_modulus();
            Obj.verifyEqual(Manipulator.Inputs.E_BOLT, 210);

            % NEXT GIVEN JPN
            Inputs.E_BOLT = nan;
            Inputs.countryCode = 'JPN';
            Manipulator = usain.inputs.PostParseManipulations(Inputs = Inputs);

            % WHEN THEN expect for JPN
            Manipulator.assign_default_bolt_youngs_modulus();
            Obj.verifyEqual(Manipulator.Inputs.E_BOLT, 205);

            % NEXT GIVIN Inputs such that the default is not assigned
            Inputs.E_BOLT = 123;
            Inputs.countryCode = 'ROW';
            Manipulator = usain.inputs.PostParseManipulations(Inputs = Inputs);

            % WHEN THEN expect that the value is the same as the original input.
            Manipulator.assign_default_bolt_youngs_modulus();
            Obj.verifyEqual(Manipulator.Inputs.E_BOLT, 123);
        end

        function assign_default_flange_youngs_modulus__happy(Obj)
            % GIVEN Inputs such that default would be assigned, first ROW.
            Inputs.E_FLANGE = nan;
            Inputs.countryCode = 'ROW';
            Manipulator = usain.inputs.PostParseManipulations(Inputs = Inputs);

            % WHEN THEN expect for ROW
            Manipulator.assign_default_flange_youngs_modulus();
            Obj.verifyEqual(Manipulator.Inputs.E_FLANGE, 210);

            % NEXT GIVEN JPN
            Inputs.E_FLANGE = nan;
            Inputs.countryCode = 'JPN';
            Manipulator = usain.inputs.PostParseManipulations(Inputs = Inputs);

            % WHEN THEN expect for JPN
            Manipulator.assign_default_flange_youngs_modulus();
            Obj.verifyEqual(Manipulator.Inputs.E_FLANGE, 205);

            % NEXT GIVIN Inputs such that the default is not assigned
            Inputs.E_FLANGE = 123;
            Inputs.countryCode = 'ROW';
            Manipulator = usain.inputs.PostParseManipulations(Inputs = Inputs);

            % WHEN THEN expect that the value is the same as the original input.
            Manipulator.assign_default_flange_youngs_modulus();
            Obj.verifyEqual(Manipulator.Inputs.E_FLANGE, 123);
        end

        function assign_default_flange_steel_type__happy(Obj)
            % GIVEN Inputs such that default would be assigned, first ROW.
            Inputs.FLANGE_STEEL_TYPE = '';
            Inputs.countryCode = 'ROW';
            Manipulator = usain.inputs.PostParseManipulations(Inputs = Inputs);

            % WHEN THEN expect for ROW
            Manipulator.assign_default_flange_steel_type();
            Obj.verifyEqual(Manipulator.Inputs.FLANGE_STEEL_TYPE, 'S355');

            % NEXT GIVEN JPN
            Inputs.FLANGE_STEEL_TYPE = '';
            Inputs.countryCode = 'JPN';
            Manipulator = usain.inputs.PostParseManipulations(Inputs = Inputs);

            % WHEN THEN expect for JPN
            Manipulator.assign_default_flange_steel_type();
            Obj.verifyEqual(Manipulator.Inputs.FLANGE_STEEL_TYPE, 'SF520');

            % NEXT GIVIN Inputs such that the default is not assigned
            Inputs.FLANGE_STEEL_TYPE = 'SomeSteelType';
            Inputs.countryCode = 'ROW';
            Manipulator = usain.inputs.PostParseManipulations(Inputs = Inputs);

            % WHEN THEN expect that the value is the same as the original input.
            Manipulator.assign_default_flange_steel_type();
            Obj.verifyEqual(Manipulator.Inputs.FLANGE_STEEL_TYPE, 'SomeSteelType');
        end

        function assign_default_bolt_resistance_jpn__happy(Obj)
            % GIVEN Inputs such that default would be assigned, first ROW.
            Inputs.PSF_BOLT_RESISTANCE_JPN = nan;
            Inputs.countryCode = 'ROW';
            Manipulator = usain.inputs.PostParseManipulations(Inputs = Inputs);

            % WHEN THEN expect for ROW
            Manipulator.assign_default_bolt_resistance_jpn();
            Obj.verifyEqual(Manipulator.Inputs.PSF_BOLT_RESISTANCE_JPN, nan);

            % NEXT GIVEN JPN
            Inputs.PSF_BOLT_RESISTANCE_JPN = nan;
            Inputs.countryCode = 'JPN';
            Manipulator = usain.inputs.PostParseManipulations(Inputs = Inputs);

            % WHEN THEN expect for JPN
            Manipulator.assign_default_bolt_resistance_jpn();
            Obj.verifyEqual(Manipulator.Inputs.PSF_BOLT_RESISTANCE_JPN, [1.25 1.875 1.0]);

            % NEXT GIVIN Inputs such that the default is not assigned
            Inputs.PSF_BOLT_RESISTANCE_JPN = 123;
            Inputs.countryCode = 'ROW';
            Manipulator = usain.inputs.PostParseManipulations(Inputs = Inputs);

            % WHEN THEN expect that the value is the same as the original input.
            Manipulator.assign_default_bolt_resistance_jpn();
            Obj.verifyEqual(Manipulator.Inputs.PSF_BOLT_RESISTANCE_JPN, 123);
        end

        function assign_default_bolt_resistance_jpn_tag__happy(Obj)
            % GIVEN Inputs such that default would be assigned, first ROW.
            Inputs.PSF_BOLT_RESISTANCE_JPN_TAG = '';
            Inputs.countryCode = 'ROW';
            Manipulator = usain.inputs.PostParseManipulations(Inputs = Inputs);

            % WHEN THEN expect for ROW
            Manipulator.assign_default_bolt_resistance_jpn_tag();
            Obj.verifyEqual(Manipulator.Inputs.PSF_BOLT_RESISTANCE_JPN_TAG, '');

            % NEXT GIVEN JPN
            Inputs.PSF_BOLT_RESISTANCE_JPN_TAG = '';
            Inputs.countryCode = 'JPN';
            Manipulator = usain.inputs.PostParseManipulations(Inputs = Inputs);

            % WHEN THEN expect for JPN
            Manipulator.assign_default_bolt_resistance_jpn_tag();
            Obj.verifyEqual(Manipulator.Inputs.PSF_BOLT_RESISTANCE_JPN_TAG, {'shortTerm' 'longTerm' 'seismic'});

            % NEXT GIVIN Inputs such that the default is not assigned
            Inputs.PSF_BOLT_RESISTANCE_JPN_TAG = 'SomeRandomTag';
            Inputs.countryCode = 'ROW';
            Manipulator = usain.inputs.PostParseManipulations(Inputs = Inputs);

            % WHEN THEN expect that the value is the same as the original input.
            Manipulator.assign_default_bolt_resistance_jpn_tag();
            Obj.verifyEqual(Manipulator.Inputs.PSF_BOLT_RESISTANCE_JPN_TAG, 'SomeRandomTag');
        end

        function assign_default_do_assess_uls__happy(Obj)
            % GIVEN Inputs such that default would be assigned, first ROW.
            Inputs.DO_ASSESS_ULS = nan;
            Inputs.countryCode = 'ROW';
            Manipulator = usain.inputs.PostParseManipulations(Inputs = Inputs);

            % WHEN THEN expect for ROW
            Manipulator.assign_default_do_assess_uls();
            Obj.verifyEqual(Manipulator.Inputs.DO_ASSESS_ULS, true);

            % NEXT GIVEN JPN
            Inputs.DO_ASSESS_ULS = nan;
            Inputs.countryCode = 'JPN';
            Manipulator = usain.inputs.PostParseManipulations(Inputs = Inputs);

            % WHEN THEN expect for JPN
            Manipulator.assign_default_do_assess_uls();
            Obj.verifyEqual(Manipulator.Inputs.DO_ASSESS_ULS, false);

            % NEXT GIVIN Inputs such that the default is not assigned
            Inputs.DO_ASSESS_ULS = 123;
            Inputs.countryCode = 'ROW';
            Manipulator = usain.inputs.PostParseManipulations(Inputs = Inputs);

            % WHEN THEN expect that the value is the same as the original input.
            Manipulator.assign_default_do_assess_uls();
            Obj.verifyEqual(Manipulator.Inputs.DO_ASSESS_ULS, 123);
        end

        function assign_default_do_assess_uls_jpn__happy(Obj)
            % GIVEN Inputs such that default would be assigned, first ROW.
            Inputs.DO_ASSESS_ULS_JPN = nan;
            Inputs.countryCode = 'ROW';
            Manipulator = usain.inputs.PostParseManipulations(Inputs = Inputs);

            % WHEN THEN expect for ROW
            Manipulator.assign_default_do_assess_uls_jpn();
            Obj.verifyEqual(Manipulator.Inputs.DO_ASSESS_ULS_JPN, false);

            % NEXT GIVEN JPN
            Inputs.DO_ASSESS_ULS_JPN = nan;
            Inputs.countryCode = 'JPN';
            Manipulator = usain.inputs.PostParseManipulations(Inputs = Inputs);

            % WHEN THEN expect for JPN
            Manipulator.assign_default_do_assess_uls_jpn();
            Obj.verifyEqual(Manipulator.Inputs.DO_ASSESS_ULS_JPN, true);

            % NEXT GIVIN Inputs such that the default is not assigned
            Inputs.DO_ASSESS_ULS_JPN = 123;
            Inputs.countryCode = 'ROW';
            Manipulator = usain.inputs.PostParseManipulations(Inputs = Inputs);

            % WHEN THEN expect that the value is the same as the original input.
            Manipulator.assign_default_do_assess_uls_jpn();
            Obj.verifyEqual(Manipulator.Inputs.DO_ASSESS_ULS_JPN, 123);
        end

        function convert_to_enum_members(Obj)
            % GIVEN
            Inputs.site = 'onshore';
            Manipulator = usain.inputs.PostParseManipulations(Inputs = Inputs);

            % WHEN
            Manipulator.convert_to_enum_members();

            % THEN
            Obj.assertInstanceOf(Manipulator.Inputs.site, 'usain.inputs.Site');
            Obj.verifyEqual(Manipulator.Inputs.site, usain.inputs.Site.ONSHORE);
        end

        function convert_to_cells_of_strings(Obj)
            % GIVEN some inputs which must be converted to string arrays but are not all input as such
            Inputs.boltOptions = {'ISO_M72'};
            Inputs.tighteningMethod = 'tension';
            Inputs.NUT_TYPE = 'ISR';
            Inputs.TIGHTENING_SIDE_INSTALLATION = 'upper';
            Inputs.TIGHTENING_SIDE_TEMP_STAGES = 'both';
            Manipulator = usain.inputs.PostParseManipulations(Inputs = Inputs);

            % WHEN, THEN
            Manipulator.convert_to_cells_of_strings();
            Obj.verifyTrue(iscellstr(Manipulator.Inputs.boltOptions));
            Obj.verifyTrue(iscellstr(Manipulator.Inputs.tighteningMethod));
            Obj.verifyTrue(iscellstr(Manipulator.Inputs.NUT_TYPE));
            Obj.verifyTrue(iscellstr(Manipulator.Inputs.TIGHTENING_SIDE_INSTALLATION));
            Obj.verifyTrue(iscellstr(Manipulator.Inputs.TIGHTENING_SIDE_TEMP_STAGES));
        end

        function convert_loads_block_inputs_to_cells__single(Obj)
            % GIVEN inputs containing single "Loads.*" block
            Inputs.Loads.dlcFilter = '.*';
            Inputs.Loads.flsFilePath = 'not\applicable\for\fixture';
            Inputs.Loads.flsScalingFactor = [1, 1];
            Inputs.Loads.flsScalingLevel = [-200, 200];
            Inputs.Loads.inclinationValue = 0.0087;
            Inputs.Loads.inclinationValueFls = 0;
            Inputs.Loads.inclinationUnit = 'deg';
            Inputs.Loads.S1FilePath = 'not\applicable\for\fixture';
            Inputs.Loads.S1ScalingFactor = [1, 1];
            Inputs.Loads.S1ScalingLevel = [-200, 200];
            Inputs.Loads.tag = 'test';
            Inputs.Loads.ulsFilePath = 'not\applicable\for\fixture';
            Inputs.Loads.ulsScalingFactor = [1, 1];
            Inputs.Loads.ulsScalingLevel = [-200, 200];
            Inputs.Loads.ALIGN_AT = 'interface';
            Manipulator = usain.inputs.PostParseManipulations(Inputs = Inputs);

            % WHEN
            Manipulator.convert_loads_block_inputs_to_cells();

            % THEN
            Obj.verifyTrue(iscellstr(Manipulator.Inputs.Loads.flsFilePath));
            Obj.verifyTrue(iscellstr(Manipulator.Inputs.Loads.S1FilePath));
            Obj.verifyTrue(iscellstr(Manipulator.Inputs.Loads.ulsFilePath));
            Obj.verifyTrue(iscellstr(Manipulator.Inputs.Loads.dlcFilter));
            Obj.verifyTrue(iscellstr(Manipulator.Inputs.Loads.tag));
            Obj.verifyTrue(iscellstr(Manipulator.Inputs.Loads.inclinationUnit));
            Obj.verifyTrue(iscell(Manipulator.Inputs.Loads.flsScalingFactor));
            Obj.verifyEqual(Manipulator.Inputs.Loads.flsScalingLevel, {{-200, 200}});
            Obj.verifyTrue(iscell(Manipulator.Inputs.Loads.S1ScalingFactor));
            Obj.verifyEqual(Manipulator.Inputs.Loads.S1ScalingLevel, {{-200, 200}});
            Obj.verifyTrue(iscell(Manipulator.Inputs.Loads.ulsScalingFactor));
            Obj.verifyEqual(Manipulator.Inputs.Loads.ulsScalingLevel, {{-200, 200}});
            Obj.verifyTrue(isnumeric(Manipulator.Inputs.Loads.inclinationValue));
        end

        function convert_loads_block_inputs_to_cells__multiple(Obj)
            % GIVEN inputs containing two "Loads.* blocks
            Inputs.Loads.tag = {'normal'; 'paranormal'};
            Inputs.Loads.flsFilePath = {'somethingWithDels'; 'exhausting'};
            Inputs.Loads.flsScalingFactor = [1.05, 1.08; 1.02, 1.06];
            Inputs.Loads.flsScalingLevel = [-200, 200; -200, 200];
            Inputs.Loads.S1FilePath = {'foo'; 'bar'};
            Inputs.Loads.S1ScalingFactor = [1.01, 1.02; 1.03, 1.04];
            Inputs.Loads.S1ScalingLevel = [-200, 200; -200, 200];
            Inputs.Loads.ulsFilePath = {'somethingContemporaneous'; 'heavy'};
            Inputs.Loads.ulsScalingFactor = [1.05, 1.08; 1.02, 1.06];
            Inputs.Loads.ulsScalingLevel = [-200, 200; -200, 200];
            Inputs.Loads.inclinationValue = [0.75; 1];
            Inputs.Loads.inclinationValueFls = [0; 0];
            Inputs.Loads.inclinationUnit = {'deg', 'mm_m'};
            Inputs.Loads.dlcFilter = {'no filter'; 'highPass'};
            Inputs.Loads.ALIGN_AT = {'interface'; 'interface'};

            Manipulator = usain.inputs.PostParseManipulations(Inputs = Inputs);

            % WHEN
            Manipulator.convert_loads_block_inputs_to_cells();

            % THEN
            Obj.verifyTrue(iscellstr(Manipulator.Inputs.Loads.flsFilePath));
            Obj.verifyTrue(iscellstr(Manipulator.Inputs.Loads.ulsFilePath));
            Obj.verifyTrue(iscellstr(Manipulator.Inputs.Loads.dlcFilter));
            Obj.verifyTrue(iscellstr(Manipulator.Inputs.Loads.tag));
            Obj.verifyTrue(iscellstr(Manipulator.Inputs.Loads.inclinationUnit));
            Obj.verifyTrue(iscell(Manipulator.Inputs.Loads.ulsScalingFactor));
            Obj.verifyEqual(Manipulator.Inputs.Loads.ulsScalingLevel, {{-200, 200}; {-200 200}});
            Obj.verifyTrue(iscell(Manipulator.Inputs.Loads.flsScalingFactor));
            Obj.verifyEqual(Manipulator.Inputs.Loads.flsScalingLevel, {{-200, 200}; {-200 200}});
            Obj.verifyTrue(iscell(Manipulator.Inputs.Loads.S1ScalingFactor));
            Obj.verifyEqual(Manipulator.Inputs.Loads.S1ScalingLevel, {{-200, 200}; {-200 200}});
            Obj.verifyTrue(isnumeric(Manipulator.Inputs.Loads.inclinationValue));
        end

        function convert_loads_block_inputs_to_cells__align_loads(Obj)
            % GIVEN inputs containing two "Loads.* blocks
            Inputs.Loads.tag = {'normal'; 'paranormal'};
            Inputs.Loads.flsFilePath = {'somethingWithDels'; 'exhausting'};
            Inputs.Loads.flsScalingFactor = [1.05, 1.08; 1.02, 1.06];
            Inputs.Loads.flsScalingLevel = [-200, 200; -200, 200];
            Inputs.Loads.S1FilePath = {'foo'; 'bar'};
            Inputs.Loads.S1ScalingFactor = [1.01, 1.02; 1.03, 1.04];
            Inputs.Loads.S1ScalingLevel = [-200, 200; -200, 200];
            Inputs.Loads.ulsFilePath = {'somethingContemporaneous'; 'heavy'};
            Inputs.Loads.ulsScalingFactor = [1.05, 1.08; 1.02, 1.06];
            Inputs.Loads.ulsScalingLevel = [-200, 200; -200, 200];
            Inputs.Loads.inclinationValue = [0.75; 1];
            Inputs.Loads.inclinationValueFls = [0; 0];
            Inputs.Loads.inclinationUnit = {'deg', 'mm_m'};
            Inputs.Loads.dlcFilter = {'no filter'; 'highPass'};

            % GIVEN default value of Loads.ALIGN_AT
            Inputs.Loads.ALIGN_AT = 'interface';

            % WHEN
            Manipulator = usain.inputs.PostParseManipulations(Inputs = Inputs);
            Manipulator.convert_loads_block_inputs_to_cells();

            % THEN
            Obj.verifyEqual(Manipulator.Inputs.Loads.ALIGN_AT, {'interface', 'interface'});
        end

        function enforce_toggles_to_logical__happy(Obj)
            % GIVEN inputs and ensure that some of the toggles are not logicals
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 1)).data;
            Inputs.DO_ASSESS_ULS = 1;
            Inputs.DO_ASSESS_FLS = true;
            Inputs.DO_TRIM_DESIGN_SPACE = 0;
            Inputs.DOOR_SEGMENT.DO_INCLUDE = 0;
            Inputs.FlangeNeckScf.WRITE_INTERMEDIATE_RESULTS = 0;
            Inputs.SGRE2.WRITE_INTERMEDIATE_RESULTS = 1;
            Manipulator = usain.inputs.PostParseManipulations(Inputs = Inputs);

            % WHEN, THEN
            Manipulator.enforce_toggles_to_logical();
            Obj.verifyClass(Manipulator.Inputs.DO_ASSESS_BOLT_PLASTICITY, 'logical');
            Obj.verifyClass(Manipulator.Inputs.DO_ASSESS_BOLT_THREAD_REQ, 'logical');
            Obj.verifyClass(Manipulator.Inputs.DO_ASSESS_FLANGE_NECK_SCF, 'logical');
            Obj.verifyClass(Manipulator.Inputs.DO_ASSESS_FLANGE_PLASTICITY, 'logical');
            Obj.verifyClass(Manipulator.Inputs.DO_ASSESS_FLS, 'logical');
            Obj.verifyClass(Manipulator.Inputs.DO_ASSESS_GAPPING, 'logical');
            Obj.verifyClass(Manipulator.Inputs.DO_ASSESS_SCHMIDTNEUPER_APT, 'logical');
            Obj.verifyClass(Manipulator.Inputs.DO_ASSESS_SLS_PRETENSION, 'logical');
            Obj.verifyClass(Manipulator.Inputs.DO_ASSESS_ULS_JPN, 'logical');
            Obj.verifyClass(Manipulator.Inputs.DO_ASSESS_ULS, 'logical');
            Obj.verifyClass(Manipulator.Inputs.DO_SAVE_FULL_FILE, 'logical');
            Obj.verifyClass(Manipulator.Inputs.DO_TRIM_DESIGN_SPACE, 'logical');
            Obj.verifyClass(Manipulator.Inputs.DO_UPDATE_DESIGN_SPACE, 'logical');
            Obj.verifyClass(Manipulator.Inputs.DOOR_SEGMENT.DO_INCLUDE, 'logical');
            Obj.verifyClass(Manipulator.Inputs.FlangeNeckScf.WRITE_INTERMEDIATE_RESULTS, 'logical');
            Obj.verifyClass(Manipulator.Inputs.IGNORE_BOLT_EXTENDER, 'logical');
            Obj.verifyClass(Manipulator.Inputs.PLOT_STRESS_PATHS, 'logical');
            Obj.verifyClass(Manipulator.Inputs.PLOT_STRESS_TRANSFER_FUNCS, 'logical');
            Obj.verifyClass(Manipulator.Inputs.SGRE2.WRITE_INTERMEDIATE_RESULTS, 'logical');

            % ... and verify that the values are the same as the original inputs
            Obj.verifyEqual(Manipulator.Inputs.DO_ASSESS_BOLT_PLASTICITY, logical(Inputs.DO_ASSESS_BOLT_PLASTICITY));
            Obj.verifyEqual(Manipulator.Inputs.DO_ASSESS_BOLT_THREAD_REQ, logical(Inputs.DO_ASSESS_BOLT_THREAD_REQ));
            Obj.verifyEqual(Manipulator.Inputs.DO_ASSESS_FLANGE_NECK_SCF, logical(Inputs.DO_ASSESS_FLANGE_NECK_SCF));
            Obj.verifyEqual(Manipulator.Inputs.DO_ASSESS_FLANGE_PLASTICITY, logical(Inputs.DO_ASSESS_FLANGE_PLASTICITY));  % mh:ignore_style
            Obj.verifyEqual(Manipulator.Inputs.DO_ASSESS_FLS, logical(Inputs.DO_ASSESS_FLS));
            Obj.verifyEqual(Manipulator.Inputs.DO_ASSESS_GAPPING, logical(Inputs.DO_ASSESS_GAPPING));
            Obj.verifyEqual(Manipulator.Inputs.DO_ASSESS_SCHMIDTNEUPER_APT, logical(Inputs.DO_ASSESS_SCHMIDTNEUPER_APT));  % mh:ignore_style
            Obj.verifyEqual(Manipulator.Inputs.DO_ASSESS_SLS_PRETENSION, logical(Inputs.DO_ASSESS_SLS_PRETENSION));
            Obj.verifyEqual(Manipulator.Inputs.DO_ASSESS_ULS_JPN, logical(Inputs.DO_ASSESS_ULS_JPN));
            Obj.verifyEqual(Manipulator.Inputs.DO_ASSESS_ULS, logical(Inputs.DO_ASSESS_ULS));
            Obj.verifyEqual(Manipulator.Inputs.DO_SAVE_FULL_FILE, logical(Inputs.DO_SAVE_FULL_FILE));
            Obj.verifyEqual(Manipulator.Inputs.DO_TRIM_DESIGN_SPACE, logical(Inputs.DO_TRIM_DESIGN_SPACE));
            Obj.verifyEqual(Manipulator.Inputs.DO_UPDATE_DESIGN_SPACE, logical(Inputs.DO_UPDATE_DESIGN_SPACE));
            Obj.verifyEqual(Manipulator.Inputs.DOOR_SEGMENT.DO_INCLUDE, logical(Inputs.DOOR_SEGMENT.DO_INCLUDE));
            Obj.verifyEqual(Manipulator.Inputs.FlangeNeckScf.WRITE_INTERMEDIATE_RESULTS, logical(Inputs.FlangeNeckScf.WRITE_INTERMEDIATE_RESULTS));  % mh:ignore_style
            Obj.verifyEqual(Manipulator.Inputs.IGNORE_BOLT_EXTENDER, logical(Inputs.IGNORE_BOLT_EXTENDER));
            Obj.verifyEqual(Manipulator.Inputs.PLOT_STRESS_PATHS, logical(Inputs.PLOT_STRESS_PATHS));
            Obj.verifyEqual(Manipulator.Inputs.PLOT_STRESS_TRANSFER_FUNCS, logical(Inputs.PLOT_STRESS_TRANSFER_FUNCS));
            Obj.verifyEqual(Manipulator.Inputs.SGRE2.WRITE_INTERMEDIATE_RESULTS, logical(Inputs.SGRE2.WRITE_INTERMEDIATE_RESULTS));  % mh:ignore_style
        end

        function expand_design_variables__happy(Obj)
            % GIVEN 3 boltOptions and a variation of allowed inputs (some with 1 value and some with 3 values) for
            % design variables that must have the same amount after the manipulation.
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 1)).data;
            Inputs.boltOptions = {'HV_M42', 'ISO_M64x480', 'ISO_M72x500x120'};
            Inputs.tighteningMethod = {'tension', 'tension', 'torque'};
            Inputs.minNBolts = [100, 200, 300];

            % AND using two BoltFls blocks
            Inputs.BoltFls.BOLT_FORCE_MODEL = ["schmidtneuper"; "sgre2"];
            Inputs.BoltFls.CUSTOM_PRELOAD = {nan; [1234 5678 9123]};
            Inputs.BoltFls.PRELOAD_LOSS_FACTOR_FLS = [0.90; 0.90];
            Inputs.BoltFls.PSF_BOLT_MATERIAL_FLS = [1.25; 1.1];
            Inputs.BoltFls.SN_CURVE_BOLT = ["EC3_DC36*"; "EC3_DC50"];
            Inputs.BoltFls.THICKNESS_EXPONENT_BOLT = [0.25; 0.10];
            Inputs.BoltFls.TARGET_PM_SUM = [0.9; 1.0];

            % WHEN
            Manipulator = usain.inputs.PostParseManipulations(Inputs = Inputs);
            Manipulator.expand_design_variables();

            % THEN expect all vars involved to have the same amount
            Obj.verifyTrue(numel(Manipulator.Inputs.minFlangeWidth) == 3);
            Obj.verifyTrue(numel(Manipulator.Inputs.maxFlangeWidth) == 3);
            Obj.verifyTrue(numel(Manipulator.Inputs.minFlangeThickn) == 3);
            Obj.verifyTrue(numel(Manipulator.Inputs.maxFlangeThickn) == 3);
            Obj.verifyTrue(numel(Manipulator.Inputs.minNBolts) == 3);
            Obj.verifyTrue(numel(Manipulator.Inputs.maxNBolts) == 3);
            Obj.verifyTrue(numel(Manipulator.Inputs.diamBoltHole) == 3);
            Obj.verifyTrue(numel(Manipulator.Inputs.diamBoltCircle) == 3);
            Obj.verifyTrue(numel(Manipulator.Inputs.TOOL_DIMENSION_CIRC_DIR) == 3);
            Obj.verifyTrue(numel(Manipulator.Inputs.TOOL_DIMENSION_RADIAL_DIR) == 3);
            Obj.verifyTrue(numel(Manipulator.Inputs.lengthBoltExtender) == 3);
            Obj.verifyTrue(numel(Manipulator.Inputs.tighteningMethod) == 3);
            Obj.verifyTrue(numel(Manipulator.Inputs.NUT_TYPE) == 3);
            Obj.verifyTrue(numel(Manipulator.Inputs.CUSTOM_WASHER_DIAM_INNER) == 3);
            Obj.verifyTrue(numel(Manipulator.Inputs.CUSTOM_WASHER_DIAM_OUTER) == 3);
            Obj.verifyTrue(numel(Manipulator.Inputs.CUSTOM_WASHER_THICKNESS) == 3);
            Obj.verifyTrue(numel(Manipulator.Inputs.FlangeGapping.CUSTOM_PRELOAD) == 3);
            Obj.verifyTrue(numel(Manipulator.Inputs.SlsPretension.CUSTOM_PRELOAD) == 3);
            Obj.verifyTrue(numel(Manipulator.Inputs.B_MIN) == 3);

            % AND that from the BoltFLS blocks only the CUSTOM_PRELOAD is expanded, the rest should have a single value
            Obj.verifyEqual(Manipulator.Inputs.BoltFls(1).BOLT_FORCE_MODEL, "schmidtneuper");
            Obj.verifyEqual(Manipulator.Inputs.BoltFls(2).BOLT_FORCE_MODEL, "sgre2");
            Obj.verifyEqual(Manipulator.Inputs.BoltFls(1).CUSTOM_PRELOAD, [nan nan nan]);
            Obj.verifyEqual(Manipulator.Inputs.BoltFls(2).CUSTOM_PRELOAD, [1234 5678 9123]);
            Obj.verifyEqual(Manipulator.Inputs.BoltFls(1).PSF_BOLT_MATERIAL_FLS, 1.25);
            Obj.verifyEqual(Manipulator.Inputs.BoltFls(2).PSF_BOLT_MATERIAL_FLS, 1.1);
            Obj.verifyEqual(Manipulator.Inputs.BoltFls(1).SN_CURVE_BOLT, "EC3_DC36*");
            Obj.verifyEqual(Manipulator.Inputs.BoltFls(2).SN_CURVE_BOLT, "EC3_DC50");
            Obj.verifyEqual(Manipulator.Inputs.BoltFls(1).THICKNESS_EXPONENT_BOLT, 0.25);
            Obj.verifyEqual(Manipulator.Inputs.BoltFls(2).THICKNESS_EXPONENT_BOLT, 0.1);
            Obj.verifyEqual(Manipulator.Inputs.BoltFls(1).TARGET_PM_SUM, 0.9);
            Obj.verifyEqual(Manipulator.Inputs.BoltFls(2).TARGET_PM_SUM, 1.0);
        end

        function assign_default_nut_type(Obj)
            % GIVEN some valid bolt labels and tightening methods
            Inputs.boltOptions = {'HV_M42', 'ISO_M64', 'ISO_M72'};
            Inputs.tighteningMethod = {'torque' 'torque' 'tension'};
            Inputs.NUT_TYPE = cell(1, 3);

            Manipulator = usain.inputs.PostParseManipulations(Inputs = Inputs);

            % WHEN
            Manipulator.assign_default_nut_type();

            % THEN
            Obj.assertEqual(Manipulator.Inputs.NUT_TYPE, {'HV', 'ISO', 'ISR'});
        end

        function update_stepsize_width_for_t_flange(Obj)
            % GIVEN: T-flange with odd STEPSIZE_WIDTH
            Inputs = Obj.applyFixture(usain.inputs.test.fixtures.ManipulatedInputsFixture(n = 1)).data;
            Inputs.flangeType = 'T';
            Inputs.STEPSIZE_WIDTH = 1e-3;

            Manipulator = usain.inputs.PostParseManipulations(Inputs = Inputs);

            % WHEN
            Manipulator.update_stepsize_width_for_t_flange();

            % THEN
            Obj.verifyEqual(Manipulator.Inputs.STEPSIZE_WIDTH, 2e-3);
        end

    end

    methods (Test, TestTags = {'integration'})

        function convert_to_si_units__happy(Obj)
            % GIVEN some dummy input file
            Obj.testDir = fileparts(mfilename('fullpath'));
            filePath = Obj.get_file_path('data\dummy.inp');
            TestObj = USAIN();
            TestObj.Logger.level = logging.Level.WARNING;
            TestObj.read_parse_validate_inputfile(filePath, false);

            % WHEN, THEN USAIN.read_parse_validate_inputfile runs smoothly to
            % obtain parsed inputs / inputfile without errors or warnings
            f = @() TestObj.read_parse_validate_inputfile(filePath, false);
            Obj.verify_no_warning_logged(f);

            % WHEN performing unit conversion to SI
            Manipulator = usain.inputs.PostParseManipulations(Inputs = TestObj.Inputs);
            Manipulator.expand_design_variables();
            Manipulator.convert_loads_block_inputs_to_cells();
            Manipulator.convert_inputs_to_si_units();

            % THEN spot check a few data points
            Obj.verifyEqual(Manipulator.Inputs.zFlange, -19.88);
            Obj.verifyEqual(Manipulator.Inputs.diameter, 7);
            Obj.verifyEqual(Manipulator.Inputs.thicknNoseUp, 0.060);
            Obj.verifyEqual(Manipulator.Inputs.minFlangeThickn, [0.160, 0.160, 0.160]);
            Obj.verifyEqual(Manipulator.Inputs.maxFlangeWidth, [0.370, 0.370, 0.370]);
            Obj.verifyEqual(Manipulator.Inputs.BoltFls(1).CUSTOM_PRELOAD, [nan, nan, nan]);
            Obj.verifyEqual(Manipulator.Inputs.BoltFls(2).CUSTOM_PRELOAD, 1e3 * [1900, 2450, 1234]);
            Obj.verifyEqual(Manipulator.Inputs.SGRE2.FLANGE_TILT_VALUE, 0.00873, 'RelTol', 1e-3);
            Obj.verifyEqual(Manipulator.Inputs.Loads.inclinationValue, [0.75 / 180 * pi; 10 / 1000], 'RelTol', 1e-6);
            Obj.verifyEqual(Manipulator.Inputs.Loads.inclinationValueFls, [0.125 / 180 * pi; 0], 'RelTol', 1e-6);
        end

        function run__happy(Obj)
            % GIVEN some dummy input file
            Obj.testDir = fileparts(mfilename('fullpath'));
            filePath = Obj.get_file_path('data\dummy.inp');
            TestObj = USAIN();
            TestObj.Logger.level = logging.Level.WARNING;
            TestObj.read_parse_validate_inputfile(filePath, false);

            % WHEN, THEN
            Manipulator = usain.inputs.PostParseManipulations(Inputs = TestObj.Inputs);
            Actual = Obj.verify_error_free(@() Manipulator.run());
            Obj.verifyClass(Actual, 'struct');
        end

    end

end
