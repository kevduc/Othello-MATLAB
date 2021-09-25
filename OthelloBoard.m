classdef OthelloBoard < handle
    properties (Access = private, Constant)
        DefaultBoardSize = [8 8]
        InitTokensPos = cat(3, [0 1; 0 1], [0 1; 1 0])
    end
    properties (SetObservable, Access = private)
        table
    end
    events
        Updated
    end
    
    methods
        function obj = OthelloBoard(boardSize)
            if nargin == 0
                boardSize = OthelloBoard.DefaultBoardSize;
            end
            assert(min(boardSize) >= 2, 'Board size must be at least 2x2!');
            
            addlistener(obj,'table','PostSet',@(src,evt)notify(obj,'Updated'));
            obj.table = zeros(boardSize);
        end
        
        function reset(obj)
            obj.table(:) = 0;
            obj.initTokens(Player.White);
            obj.initTokens(Player.Black);
        end
        
        function initTokens(obj, player)
            middle = floor(size(obj.table)/2);
            iw = sub2ind(size(obj.table),...
                         middle(1)+obj.InitTokensPos(1,:,player),...
                         middle(2)+obj.InitTokensPos(2,:,player));
            obj.table(iw) = player;
        end
        
        function putToken(obj, player, row, col)
            obj.table(row,col) = player;
        end
        
        function flipTokens(obj, player, indexes)
            obj.table(indexes) = player;
        end
        
        function count = countTokens(obj, player)
            count = sum(sum(obj.table == player));
        end
        
        function tf = inBoard(obj, row, col)
            tf = all([row col] <= size(obj.table)) && all([row col] >= 1);
        end
        
        function tf = isFree(obj, row, col)
            tf = (obj.table(row,col) == Player.None);
        end
        
        function [rows, cols] = getTokensPos(obj, player)
            [rows, cols] = find(obj.table == player);
        end
        
        function tf = canPlay(obj, player)
            tf = false;
            for row = 1:size(obj.table,1)
                for col = 1:size(obj.table,2)
                    if obj.isFree(row,col)
                        idx = obj.getAffectedCells(player, row, col);
                        tf = ~isempty(idx);
                        if tf; return; end
                    end
                end
            end
        end
        
        function indexes = getAffectedCells(obj, player, row, col)
            indexes = [];
            v = 1:max(size(obj.table)-1);
            for i = -1:1
                rows = i*v+row;
                rows = rows(rows > 0 & rows <= size(obj.table,1));
                for j = -1:1
                    cols = j*v+col;
                    cols = cols(cols > 0 & cols <= size(obj.table,2));
                    m = min(length(rows), length(cols));
                    idx = sub2ind(size(obj.table),rows(1:m),cols(1:m));
                    line = obj.table(idx);
                    firstToken = find(line == player | line == 0, 1);
                    if ~isempty(firstToken) && firstToken > 1 && obj.table(idx(firstToken)) == player
                        indexes = [indexes, idx(1:firstToken-1)]; %#ok<AGROW>
                    end
                end
            end
        end
    end
    
    methods (Access = private)
    end
    
end

