classdef OthelloNET < handle
    properties (SetAccess = private, GetAccess = public)
        connection
        receivedCoords
    end
    properties (SetObservable, SetAccess = private, GetAccess = public)
        opponentStatus
    end
    events
        CoordsReceived
    end
    
    methods
        function obj = OthelloNET(opponent)
            obj.connection = tcpip(opponent, 55000, 'NetworkRole', 'client');
            obj.connection.ReadAsyncMode = 'continuous';
            obj.connection.BytesAvailableFcnMode = 'terminator';
            obj.connection.BytesAvailableFcn = @obj.dataReceived;
            obj.opponentStatus = 'unknown';
        end
        
        function connect(obj, role)
            if nargin == 1
                try
                    fopen(obj.connection);
                catch
                    obj.opponentStatus = 'notstarted';
                    obj.connection.NetworkRole = 'server';
                    fopen(obj.connection);
                end
            else
                if strcmp(role,'server')
                    obj.opponentStatus = 'notstarted';
                    obj.connection.NetworkRole = 'server';
                    fopen(obj.connection);
                else
                    connected = false;
                    while ~connected
                        try
                            fopen(obj.connection);
                            connected = true;
                        catch
                        end
                    end
                end     
            end
            obj.opponentStatus = 'ready';
        end
        
        function send(obj, coord)
            fwrite(obj.connection, [num2str(coord) char(10)]);
        end
        
        function sendStatus(obj, status)
            fwrite(obj.connection, [status char(10)]);
        end
        
        function delete(obj)
            if strcmp(obj.connection.Status,'open')
                fclose(obj.connection);
            end
        end
    end
    methods (Access = private)
        function dataReceived(obj, ~, ~)
            data = fread(obj.connection, obj.connection.BytesAvailable);
            str = char(data(1:end-1)');
            if strcmp(str,'closed')
                obj.opponentStatus = 'closed';
            else
                values = str2double(split(str))';
                if any(isnan(values)) || any(size(values) ~= [1 2])
                    warning('Received invalid status or malformed coordinates.');
                else
                    obj.receivedCoords = values;
                    notify(obj,'CoordsReceived');
                end
            end
        end
    end
end