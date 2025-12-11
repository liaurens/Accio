classdef ResilienceModelFixture < matlab.unittest.fixtures.Fixture
    % Fixture for USAIN inputs with representative values for the use in usain.model.ResilienceModel tests

    properties
        data usain.model.ResilienceModel
        type char
    end

    methods

        function Obj = ResilienceModelFixture(type)
            Obj.type = type;
        end

        function setup(Obj)
            switch Obj.type
                case 'HV_single'
                    Obj.data = Obj.get_data_hv_single();
                case 'ISO_multi'
                    Obj.data = Obj.get_data_iso_multi();
                case 'mixed'
                    Obj.data = Obj.get_data_mixed();
                case 'JIS_single'
                    error('Implementation error.');
                    % TODO: Implement and extend `ResilienceModel_Test` with cases using JIS bolts (expect same results
                    % as for HV bolts)
                otherwise
                    error('Unknown ResilienceModelFixture type: %s', Obj.type);
            end
        end

        function data = get_data_hv_single(~)
            % Set up data structure according to properties of `usain.model.ResilienceModel`, representing a single
            % design point with an HV bolt assembly

            data = usain.model.ResilienceModel();
            data.Bolt = struct();
            data.Extender = struct();
            data.Nut = struct();
            data.Washer = struct();

            data.Bolt.type = 'hex';
            data.Bolt.diam = 0.064;
            data.Bolt.len = 0.430;
            data.Bolt.lenThread = 0.100;
            data.Bolt.minorDiameter = 0.0575048095;
            data.Bolt.pitchDiameter = 0.0601028857;
            data.Extender.diamIn = 0.067;
            data.Extender.diamOut = 0.120;
            data.Extender.len = 0.010;
            data.Nut.diam = 0.1155;
            data.Washer.diamIn = 0.066;
            data.Washer.diamOut = 0.115;
            data.Washer.len = 0.010;

            data.eModulusBolt = 210e6;
            data.eModulusFlange = 210e6;
            data.doIgnoreExtender = false;
            data.diameterBoltHole = 0.070;
            data.flangeThickness = 0.120;
        end

        function data = get_data_iso_multi(~)
            % Set up data structure according to properties of `usain.model.ResilienceModel`, representing multiple (2)
            % design points with an ISO bolt assembly

            data = usain.model.ResilienceModel();
            data.Bolt = struct();
            data.Extender = struct();
            data.Nut = struct();
            data.Washer = struct();

            data.Bolt.type = {'stud', 'stud'};
            data.Bolt.diam = [0.072, 0.072];
            data.Bolt.len = [0.570, 0.650];
            data.Bolt.lenThread = [0.200, 0.200];
            data.Bolt.minorDiameter = [0.0655048095, 0.0655048095];
            data.Bolt.pitchDiameter = [0.0681028857, 0.0681028857];
            data.Extender.diamIn = [0.075, 0.075];
            data.Extender.diamOut = [0.130, 0.130];
            data.Extender.len = [0.020, 0.0];
            data.Nut.diam = [0.1212, 0.125];
            data.Washer.diamIn = [0.074, 0.074];
            data.Washer.diamOut = [0.125, 0.125];
            data.Washer.len = [0.010, 0.0];

            data.eModulusBolt = 210e6;
            data.eModulusFlange = 210e6;
            data.doIgnoreExtender = false;
            data.diameterBoltHole = [0.078, 0.082];
            data.flangeThickness = [0.155, 0.201];
        end

        function data = get_data_mixed(Obj)

            % Get data structs for 'HV_single' and 'ISO_multi'
            dataBolt = Obj.get_data_hv_single();
            dataStud = Obj.get_data_iso_multi();

            % Concatenate data (hack alert!)
            data = dataBolt;
            for field = ["Bolt", "Extender", "Nut", "Washer"]
                for subfield = string(fieldnames(dataBolt.(field)))'
                    data.(field).(subfield) = [dataBolt.(field).(subfield), dataStud.(field).(subfield)];
                end
            end
            for field = ["diameterBoltHole", "flangeThickness"]
                data.(field) = [dataBolt.(field), dataStud.(field)];
            end
        end

    end

    methods (Access = protected)

        function bool = isCompatible(Obj, Other)
            bool = strcmp(Obj.type, Other.type);
        end

    end

end
