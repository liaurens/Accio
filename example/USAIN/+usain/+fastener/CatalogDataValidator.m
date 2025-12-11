classdef CatalogDataValidator < matlab.mixin.SetGet

    properties
        Exception MException
        validationFuncs cell  % Collection of validation functions
    end

    methods

        function Obj = CatalogDataValidator(catalogName)
            if ~nargin
                catalogName = '';
            end

            Obj.Exception = MException('CatalogDataValidator:ValidationError', ...
                'Error(s) found while validating %s catalog.', catalogName);
        end

        function validate(Obj, func)
            try
                func();
            catch ThisExc
                Obj.Exception = Obj.Exception.addCause(MException('', ThisExc.message));
            end
        end

        function report(Obj)
            if length(Obj.Exception.cause) >= 1
                Obj.Exception.throw();
            end
        end

    end
end
