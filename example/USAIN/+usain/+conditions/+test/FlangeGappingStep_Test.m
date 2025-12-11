classdef FlangeGappingStep_Test < UsainTest.UsainTestCase

    methods (Test, TestTags = {'integration'})

        function run__happy(~)
            % TODO: Implement this test after FlangeModel is removed from USAIN framework (WPSSD-5639)
        end

    end

    methods (Test, TestTags = {'unit'})

        function get_conditions__happy(Obj)
            % GIVEN WHEN THEN
            Obj.verifyClass(usain.conditions.FlangeGappingStep().get_conditions(), ...
                'UsainUtils.FlangeGapping');
        end

    end

end
