classdef InputsBMin < usain.inputs.run_dataclass.AInputsDataclass % mh:ignore_style
    properties
        thicknNoseUp (1, :) double
        thicknNoseLo (1, :) double
        diameter (1, :) double
        diameterReference (1, :) string
        diamBoltHole (1, :) double
    end
end
