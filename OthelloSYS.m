classdef OthelloSYS < handle
    properties (Access = private)
        board
    end
    properties (SetObservable, SetAccess = private, GetAccess = public)
        scores
        currentPlayer
    end
    events
        CannotPlay
        GameEnd
    end
    
    methods
        function obj = OthelloSYS(board)
            obj.board = board;
            obj.scores = [0 0];
            obj.currentPlayer = Player.None;
        end
        
        function initialize(obj)
            obj.reset();
        end
        
        function reset(obj)
            obj.board.reset();
            obj.scores = obj.countTokens();
            obj.currentPlayer = Player.White;
        end
        
        function err = play(obj, row, col)
            player = obj.currentPlayer;
            err = InvalidMove.None;
            
            if ~obj.board.inBoard(row, col)
                err = InvalidMove.OutOfBound;
                return
            end
            
            if ~obj.board.isFree(row, col)
                err = InvalidMove.CellOccupied;
                return
            end
            
            indexes = obj.board.getAffectedCells(player, row, col);
            if isempty(indexes)
                err = InvalidMove.NoFlipping;
                return
            end
            
            obj.board.putToken(player, row, col);
            obj.board.flipTokens(player, indexes);
            obj.scores = obj.countTokens();
            
            obj.currentPlayer = obj.currentPlayer.next();
            if ~obj.board.canPlay(obj.currentPlayer)
                player = obj.currentPlayer.next();
                notify(obj,'CannotPlay');
                obj.currentPlayer = player;
                if ~obj.board.canPlay(obj.currentPlayer)
                    notify(obj,'GameEnd');
                    return
                end
            end
        end
    end
    methods (Access = private)
        function count = countTokens(obj)
            count = [obj.board.countTokens(Player.White)...
                     obj.board.countTokens(Player.Black)];
        end
    end
end