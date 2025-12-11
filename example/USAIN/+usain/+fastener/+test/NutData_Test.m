classdef NutData_Test < Unittest.TestCase
    % See also: usain.fastener.test.BaseCatalogData_Test

    methods (Test, TestTags = {'unit'})

        function compose_nut_labels__happy(Obj)
            % GIVEN, WHEN, THEN
            Obj.assertEqual( ...
                usain.fastener.NutData.compose_nut_labels('ISO_M64', 'ISR'), ...
                "ISR_M64");
            Obj.assertEqual( ...
                usain.fastener.NutData.compose_nut_labels({'ISO_M64'}, {'ISR'}), ...
                "ISR_M64");
            Obj.assertEqual( ...
                usain.fastener.NutData.compose_nut_labels({'HV_M72', 'ISO_M42'}, {'HV', 'ISR'}), ...
                ["HV_M72", "ISR_M42"]);
        end

    end

end
