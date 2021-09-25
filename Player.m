classdef Player < uint32
    enumeration
        None  (0)
        White (1)
        Black (2)
    end
    
    methods
        function player = next(obj)
            player = Player(mod(obj, Player.count()) + 1);
        end
    end
    methods (Static)
        function n = count()
            n = length(enumeration('Player')) - 1;
        end
    end
end

