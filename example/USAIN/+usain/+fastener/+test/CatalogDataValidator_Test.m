classdef CatalogDataValidator_Test < Unittest.TestCase

    methods (Test, TestTags = {'unit'})

        function validate__adds_exception_if_error(Obj)
            % GIVEN an empty validator
            Val = usain.fastener.CatalogDataValidator('testing');
            Obj.assumeLength(Val.Exception.cause, 0);

            % WHEN we validate something that errors
            Val.validate(@() error('this will add a cause'));

            % THEN we expect an exception to be added
            Obj.assertLength(Val.Exception.cause, 1);
        end

        function validate__adds_no_exception_if_no_error(Obj)
            % GIVEN an empty validator
            Val = usain.fastener.CatalogDataValidator('testing');
            Obj.assumeLength(Val.Exception.cause, 0);

            % WHEN we validate something that does not error
            Val.validate(@() 'this will not add a cause');

            % THEN we expect no exception to be added
            Obj.assertLength(Val.Exception.cause, 0);
        end

        function report__nothing_if_no_cause(Obj)  %#ok
            % GIVEN a validator without failing validation function
            Val = usain.fastener.CatalogDataValidator('testing');
            Val.validate(@() 'this will not add a cause');

            % WHEN we report the validations
            % THEN we expect nothing
            Val.report();
        end

        function report__error_if_cause(Obj)
            % GIVEN a validator with failing validation function
            Val = usain.fastener.CatalogDataValidator('testing');
            Val.validate(@() error('this will add a cause'));

            % WHEN we report the validations
            % THEN we expect the cause to be thrown
            Obj.assertError(@() Val.report(), 'CatalogDataValidator:ValidationError');
        end

    end
end
