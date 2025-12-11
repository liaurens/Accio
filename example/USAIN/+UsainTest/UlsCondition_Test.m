classdef UlsCondition_Test < UsainTest.UsainTestCase

    methods (Test, TestTags = {'unit'})

        function get_uls_condition_for_countrycode__jpn(Obj)
            % GIVEN an empty UsainUtils.ConditContainer instance
            Condits = UsainUtils.ConditContainer();

            % WHEN we query the ULS condition when input countryCode is 'JPN'
            % THEN
            actual = UsainUtils.UlsCondition.get_uls_condition_for_countrycode(Condits, 'JPN');
            Obj.assertInstanceOf(actual, 'UsainUtils.UltimateLimitStateJpn');
        end

        function get_uls_condition_for_countrycode__row(Obj)
            % GIVEN an empty UsainUtils.ConditContainer instance
            Condits = UsainUtils.ConditContainer();

            % WHEN we query the ULS condition when input countryCode is 'ROW'
            % THEN
            actual = UsainUtils.UlsCondition.get_uls_condition_for_countrycode(Condits, 'ROW');
            Obj.assertInstanceOf(actual, 'UsainUtils.UltimateLimitState');
        end

        function get_uls_condition_for_countrycode__invalid_country(Obj)
            % GIVEN an empty UsainUtils.ConditContainer instance
            Condits = UsainUtils.ConditContainer();

            % WHEN we query the ULS condition when input countryCode is something invalid
            % THEN
            Obj.assertError( ...
                @() UsainUtils.UlsCondition.get_uls_condition_for_countrycode(Condits, 'NLD'), ...
                'UlsCondition:UnsupportedCountryCode');
        end

    end
end
