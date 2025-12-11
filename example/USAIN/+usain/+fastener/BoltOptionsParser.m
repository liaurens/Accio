classdef BoltOptionsParser < matlab.mixin.SetGet
    % Helper class to extract information from USAIN input 'boltOptions'

    properties
        input  % [1 x N] Value(s) for input 'boltOptions'
    end
    properties (Dependent)
        nOptions int  % Number of bolt options inputs

        label  % Combination of fastener system and metric size (e.g. HV_M42)
        boltSizeString % String only specifying the metric size as string (e.g. "M42")
        diameter  % Diameter extracted from `input` (always provided), converted to [m]
        inputBoltLength  % Length of bolt extracted from `input` (only if provided), converted to [m]
        inputThreadLength  % Length of thread extracted from `input` (only if provided), converted to [m]

        isStandardBoltLength  % Boolean mask to indicate entries in Obj.input with standard bolt length
        isStandardThreadLength  % Boolean mask to indicate entries in Obj.input with standard thread length
    end
    properties (Constant, Hidden)
        REGEX_BOLTSIZESTRING = 'M(\d+)'
        REGEX_BOLTOPS = '^(\w+)\_(M\d+)(x(\d+))?(x(\d+))?$'  % bolt and thread lengths are optional
        REGEX_LABEL = '^(\w+\_M\d+)'
        REGEX_DIAMETER = '(?<=^\w+\_M)\d+'
        REGEX_LENBOLT = '(?<=^\w+\_M\d+x)\d+'
        REGEX_LENTHREAD = '(?<=^\w+\_M\d+x\d+x)\d+'
    end

    methods

        function Obj = BoltOptionsParser(input)
            Obj.input = input;
        end

        function [pass, msg] = verify_feasible_thread_length(Obj)

            tooLongThreadLen = Obj.inputThreadLength > (Obj.inputBoltLength + 1e-6);
            pass = all(~tooLongThreadLen);
            if ~pass
                % Not OK, prepare error message
                msg = sprintf(['Infeasible thread length for input "boltOptions" found:', ...
                    '\n\n\t%s\n\n', ...
                    '\t==> Length of threads must be smaller than or equal to the fastener length\n', ...
                    '\t    Note that for studs, the specified thread length is present on both sides'], ...
                    strjoin(Obj.input(tooLongThreadLen), ', '));
            else
                msg = '';
            end

        end

        function validate_format(Obj)
            % Checks input format(s):
            %   SYS_M12x345x678
            %    1   2   3*  4*
            %
            % 1: Bolt system (e.g. HV, ISO)
            % 2: Metric size of bolt (M42, M48, etc.)
            % 3: (*optional) Bolt length
            % 4: (*optional) Thread length

            isMatch = ~cellfun(@isempty, regexpi(Obj.input, Obj.REGEX_BOLTOPS));
            assert(all(isMatch), 'BoltOptionsParser:InvalidFormat', ...
                ['Incorrect format for input "boltOptions" found: %s.\n', ...
                'Expected format like ISO_M42, ISO_M48x330, ISO_M56x380x90.'], ...
                strjoin(Obj.input(~isMatch), ', '));
        end

        function set.input(Obj, value)
            validateattributes(value, {'char', 'cell', 'string'}, {'nonempty'}, '', 'boltOptions');
            Obj.input = cellstr(value);
        end

        function str = get.boltSizeString(Obj)
            str = string(regexp(Obj.input, Obj.REGEX_BOLTSIZESTRING, 'once', 'match'));
        end

        function value = get.label(Obj)
            value = regexp(Obj.input, Obj.REGEX_LABEL, 'once', 'match');
        end

        function value = get.diameter(Obj)
            match = regexp(Obj.input, Obj.REGEX_DIAMETER, 'once', 'match');
            value = 1e-3 * str2double(match);
        end

        function value = get.inputBoltLength(Obj)
            match = regexp(Obj.input, Obj.REGEX_LENBOLT, 'once', 'match');
            value = 1e-3 * str2double(match);
        end

        function value = get.inputThreadLength(Obj)
            match = regexp(Obj.input, Obj.REGEX_LENTHREAD, 'once', 'match');
            value = 1e-3 * str2double(match);
        end

        function value = get.nOptions(Obj)
            value = numel(Obj.input);
        end

        function value = get.isStandardBoltLength(Obj)
            % True if length is a standard length, false otherwise (also if length was not defined)
            value = false(1, Obj.nOptions);
            for iOpt = 1:Obj.nOptions
                standardLengths = usain.fastener.FastenerData.get_standard_bolt_lengths(Obj.label{iOpt});
                value(iOpt) = any(abs(Obj.inputBoltLength(iOpt) - standardLengths) < 1e-6);
            end
        end

        function value = get.isStandardThreadLength(Obj)
            % True if length is a standard length, false otherwise (also if length was not defined)
            value = false(1, Obj.nOptions);
            for iOpt = 1:Obj.nOptions
                standardLength = usain.fastener.FastenerData.get_standard_thread_length(Obj.label{iOpt});
                if isinf(standardLength) && startsWith(Obj.input(iOpt), 'ISO')
                    % Fully threaded stud
                    value(iOpt) = abs(Obj.inputThreadLength(iOpt) - Obj.inputBoltLength(iOpt) / 2) < 1e-6;
                else
                    value(iOpt) = abs(Obj.inputThreadLength(iOpt) - standardLength) < 1e-6;
                end
            end
        end

    end

end
