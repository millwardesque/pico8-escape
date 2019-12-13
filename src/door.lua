log = require('log')

local door = {
    mk = function(rm1, rm2)
        local d = {
            exit1 = {
                rm = rm1,
                coords = nil
            },
            exit2 = {
                rm = rm2,
                coords = nil
            },
        }

        d.set_coords = function(self, rm, coords)
            local exit = self.my_exit(self, rm)
            exit.coords = coords
        end

        d.get_coords = function(self, rm)
            local exit = self.my_exit(self, rm)
            return exit.coords
        end

        d.my_exit = function(self, rm)
            if self.exit1.rm == rm then
                return self.exit1
            elseif self.exit2.rm == rm then
                return self.exit2
            else
                log.syslog("d["..self.exit1.rm.name..","..self.exit2.rm.name.."]: Couldn't find my exit for "..rm.name)
                return nil
            end
        end

        d.other_exit = function(self, rm)
            if self.exit1.rm == rm then
                return self.exit2
            elseif self.exit2.rm == rm then
                return self.exit1
            else
                log.syslog("d["..self.exit1.rm.name..","..self.exit2.rm.name.."]: Couldn't find other exit from "..rm.name)
                return nil
            end
        end

        return d
    end,
}
return door
