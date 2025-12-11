classdef calc_mass_components_Test < Unittest.TestCase  % mh:ignore_style

    methods (Test, TestTags = {'unit'})

        function calc_mass_hv_bolt__happy(Obj)
            % GIVEN inputs for an M48x400 HV bolt (from DASt-Ri 021)
            diameter = 0.048;
            len = 0.400;

            % WHEN, THEN
            actual = usain.fastener.calc_mass_hv_bolt(diameter, len);
            expected = 6.7623;
            Obj.assertEqual(actual, expected, 'AbsTol', 1e-4);
        end

        function calc_mass_iso_stud__happy(Obj)
            % GIVEN inputs for an M80x600 ISO stud (from DIN 976-1)
            pitchDiameter = 0.076103;
            len = 0.600;

            % WHEN, THEN
            actual = usain.fastener.calc_mass_iso_stud(pitchDiameter, len);
            expected = 21.4246;
            Obj.assertEqual(actual, expected, 'AbsTol', 1e-4);
        end

    end
end
