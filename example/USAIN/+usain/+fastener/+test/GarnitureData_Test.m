classdef GarnitureData_Test < Unittest.TestCase
    % See also: usain.fastener.test.BaseCatalogData_Test

    properties (TestParameter)
        % Inputs that are not char, string or cellstr
        notStringLike = {{'test', 1}, 123, [true, false]}

        % Invalid tighteningMethod options, for testing of validate_input()
        invalidOptions = {'ISO_HV_M42', 'OSI_M1'}
    end

    methods (Test, TestTags = {'unit'})

        function validate_bolt_nut_tool_combination__happy(Obj)
            % GIVEN valid inputs
            site = usain.inputs.Site.OFFSHORE;
            boltOptions = {'HV_M72', 'ISO_M42'};
            tighteningMethod = {'torque', 'tension'};
            nutType = {'HV', 'ISR'};

            % WHEN calling the test method with and without output arguments
            usain.fastener.GarnitureData.validate_bolt_nut_tool_combination( ...
                site, boltOptions, tighteningMethod, nutType);
            withArgout = usain.fastener.GarnitureData.validate_bolt_nut_tool_combination( ...
                site, boltOptions, tighteningMethod, nutType);

            % THEN we expect no errors, and in case of an output arg we expect a function handle to be
            % returned
            Obj.assertInstanceOf(withArgout, 'function_handle');
        end

        function validate_bolt_nut_tool_combination__invalid_combination(Obj)
            % GIVEN invalid inputs (HV bolts are never tension-tightened)
            site = usain.inputs.Site.OFFSHORE;
            boltOptions = {'HV_M72'};
            tighteningMethod = {'tension'};
            nutType = {'ISR'};

            % WHEN, THEN
            f = @() usain.fastener.GarnitureData.validate_bolt_nut_tool_combination( ...
                site, boltOptions, tighteningMethod, nutType);
            Obj.assertError(f, 'GarnitureData:validate_bolt_nut_tool_combination:ValidationError');
        end

        function validate_bolt_options__not_stringlike(Obj, notStringLike)
            % GIVEN inputs that are not string-like
            % WHEN, THEN
            f = @() usain.fastener.GarnitureData.validate_bolt_options(notStringLike);
            Obj.assertError(f, 'GarnitureData:validate_bolt_options:WrongType');
        end

        function validate_bolt_options__invalid_options(Obj, invalidOptions)
            % GIVEN invalid values for input boltOptions
            % WHEN, THEN
            f = @() usain.fastener.GarnitureData.validate_bolt_options(invalidOptions);
            Obj.assertError(f, 'GarnitureData:validate_bolt_options:InvalidLabel');
        end

        function validate_bolt_options__happy(Obj)
            % GIVEN a valid value for input boltOptions
            boltOptions = 'ISO_M42';

            % WHEN, THEN
            f = @() usain.fastener.GarnitureData.validate_bolt_options(boltOptions);
            Obj.verify_error_free(f);
        end

    end
end
