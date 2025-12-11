classdef FlangeYieldStrength_Test < Unittest.TestCase

    methods (Test, TestTags = {'unit'})

        function get_yield_strength__expected_values_for_s355(Obj)
            % GIVEN multiple queries to `usain.model.FlangeYieldStregth(...).get_yield_strength(...)` for S355 steel

            % WHEN using thickness values at the boundaries defined in the Design Brief (63mm < thickness <= 350mm)
            % THEN
            Obj.verifyEqual(usain.model.FlangeYieldStrength("S355").get_yield_strength(63e-3), 325e6);
            Obj.verifyEqual(usain.model.FlangeYieldStrength("S355").get_yield_strength(80e-3), 315e6);
            Obj.verifyEqual(usain.model.FlangeYieldStrength("S355").get_yield_strength(100e-3), 295e6);
            Obj.verifyEqual(usain.model.FlangeYieldStrength("S355").get_yield_strength(150e-3), 285e6);
            Obj.verifyEqual(usain.model.FlangeYieldStrength("S355").get_yield_strength(200e-3), 275e6);
            Obj.verifyEqual(usain.model.FlangeYieldStrength("S355").get_yield_strength(350e-3), 275e6);

            % WHEN using thickness values in between the boundaries defined in the Design Brief
            % THEN
            Obj.verifyEqual(usain.model.FlangeYieldStrength("S355").get_yield_strength(70e-3), 325e6);
            Obj.verifyEqual(usain.model.FlangeYieldStrength("S355").get_yield_strength(90e-3), 315e6);
            Obj.verifyEqual(usain.model.FlangeYieldStrength("S355").get_yield_strength(125e-3), 295e6);
            Obj.verifyEqual(usain.model.FlangeYieldStrength("S355").get_yield_strength(175e-3), 285e6);
            Obj.verifyEqual(usain.model.FlangeYieldStrength("S355").get_yield_strength(275e-3), 275e6);

            % WHEN using thickness values outside the boundaries defined in the Design Brief
            % THEN
            Obj.verifyEqual(usain.model.FlangeYieldStrength("S355").get_yield_strength(62e-3), nan);
            Obj.verifyEqual(usain.model.FlangeYieldStrength("S355").get_yield_strength(351e-3), nan);
        end

        function get_yield_strength__happy_for_non_s355_steel(Obj)
            % GIVEN multiple queries to `usain.model.FlangeYieldStregth(...).get_yield_strength(...)` for steel types
            % other than S355

            % WHEN, THEN
            Obj.verify_error_free(@() usain.model.FlangeYieldStrength("S235").get_yield_strength(100e-3));
            Obj.verify_error_free(@() usain.model.FlangeYieldStrength("S420").get_yield_strength(100e-3));
        end

        function get_yield_strength__array_input(Obj)
            % GIVEN an array of product thickness values
            productThickness = 1e-3 * [100, 101, 102];

            % WHEN
            % THEN expect an yield strength array of the same size
            Obj.verifySize(usain.model.FlangeYieldStrength("S355").get_yield_strength(productThickness), [1, 3]);
        end

        function is_flange_steel_type__happy(Obj)
            % GIVEN, WHEN, THEN
            Obj.verifyTrue(usain.model.FlangeYieldStrength("S355").is_flange_steel_type());
            Obj.verifyTrue(usain.model.FlangeYieldStrength("SF520").is_flange_steel_type());
            Obj.verifyFalse(usain.model.FlangeYieldStrength("S325").is_flange_steel_type());
            Obj.verifyFalse(usain.model.FlangeYieldStrength("S420").is_flange_steel_type());
            Obj.verifyFalse(usain.model.FlangeYieldStrength("SM520").is_flange_steel_type());
        end

        function check_steel_type__flange_steel_type(Obj)
            % GIVEN a FlangeYieldStrength instance with S355 steel (flange specific)
            YieldStr = usain.model.FlangeYieldStrength("S355");

            % WHEN
            [actualMessage, actualLevel] = YieldStr.check_steel_type();

            % THEN
            Obj.verifyEqual(actualLevel, logging.Level.NOTSET);
            Obj.verifyEmpty(actualMessage);
        end

        function check_steel_type__no_flange_steel_type(Obj)
            % GIVEN a FlangeYieldStrength instance with S420 (plate steel type)
            YieldStr = usain.model.FlangeYieldStrength("S420");

            % WHEN
            [actualMessage, actualLevel] = YieldStr.check_steel_type();

            % THEN
            Obj.verifyEqual(actualLevel, logging.Level.WARNING);
            Obj.verifyNotEmpty(actualMessage);
        end

    end
end
