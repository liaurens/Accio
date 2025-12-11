classdef get_condition_steps_Test < UsainTest.UsainTestCase  % mh:ignore_style

    methods (Test, TestTags = {'unit'})

        function get_condition_steps__length_return_arg(Obj)
            % GIVEN, WHEN
            ActualWithFlangeModel = usain.conditions.get_condition_steps("flangemodel");
            ActualWithSelectedModel = usain.conditions.get_condition_steps("selectedmodel");

            % THEN expect the same number of steps regardless of input model type, and in the same order
            Obj.assertEqual(length(ActualWithFlangeModel), length(ActualWithSelectedModel));
            for iStep = 1:length(ActualWithFlangeModel)
                Obj.verifyEqual(class(ActualWithFlangeModel{iStep}), class(ActualWithFlangeModel{iStep}));
            end

        end

        function get_condition_steps__invalid_input_arg(Obj)
            % GIVEN, WHEN, THEN
            Obj.assertRaisesMessageRegex(@() usain.conditions.get_condition_steps("foo"), 'Invalid input option.');
        end

        function get_condition_steps__sets_doRunOnSelectedModel(Obj)
            % GIVEN, WHEN
            ActualWithFlangeModel = usain.conditions.get_condition_steps("flangemodel");
            ActualWithSelectedModel = usain.conditions.get_condition_steps("selectedmodel");

            % THEN expect doRunOnSelectedModel = false for conditions in ActualWithFlangeModel
            for Condition = ActualWithFlangeModel
                Obj.assertFalse(Condition{1}.doRunOnSelectedModel);
            end

            % ... and expect doRunOnSelectedModel = true for conditions in ActualWithSelectedModel
            for Condition = ActualWithSelectedModel
                Obj.assertTrue(Condition{1}.doRunOnSelectedModel);
            end
        end

    end

end
