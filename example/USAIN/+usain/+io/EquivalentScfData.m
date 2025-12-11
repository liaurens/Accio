classdef EquivalentScfData < dataclasses.DataClass

    properties
        labels (1, :) string
        bendingScfInside (1, :) double
        bendingScfOutside (1, :) double
    end

    methods

        function S = to_struct(Obj)
            S = struct( ...
                'labels', Obj.labels, ...
                'bendingScfInside', Obj.bendingScfInside, ...
                'bendingScfOutside', Obj.bendingScfOutside);
        end

    end

    methods (Static)

        function NewObj = merge_and_sort(varargin)
            % Merge dataclasses to a single one, with sorted data
            %
            % varargin: Variable number of usain.io.EquivalentScfData dataclasses
            % NewObj: New usain.io.EquivalentScfData instance with merged, sorted data

            assert(all(cellfun(@(x) isa(x, 'usain.io.EquivalentScfData'), varargin)), ...
                'All input objects must be a usain.io.EquivalentScfData instance.');

            isEmptyObject = cellfun(@isempty, varargin);
            if all(isEmptyObject)
                NewObj = usain.io.EquivalentScfData.empty;
                return
            end
            NonemptyObjects = varargin(~isEmptyObject);

            New = struct();
            New.labels = NonemptyObjects{1}.labels;
            New.bendingScfInside = NonemptyObjects{1}.bendingScfInside;
            New.bendingScfOutside = NonemptyObjects{1}.bendingScfOutside;
            for iObj = 2:length(NonemptyObjects)
                New.labels = [New.labels, NonemptyObjects{iObj}.labels];
                New.bendingScfInside = [New.bendingScfInside, NonemptyObjects{iObj}.bendingScfInside];
                New.bendingScfOutside = [New.bendingScfOutside, NonemptyObjects{iObj}.bendingScfOutside];
            end

            % Re-order based on label
            [New.labels, iSort] = sort(New.labels);
            New.bendingScfInside = New.bendingScfInside(iSort);
            New.bendingScfOutside = New.bendingScfOutside(iSort);

            % Construct dataclass
            NewObj = usain.io.EquivalentScfData(New);
        end

    end

end
