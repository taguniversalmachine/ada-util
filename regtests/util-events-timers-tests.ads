-----------------------------------------------------------------------
--  util-events-timers-tests -- Unit tests for timers
--  Copyright (C) 2017 Stephane Carrez
--  Written by Stephane Carrez (Stephane.Carrez@gmail.com)
--
--  Licensed under the Apache License, Version 2.0 (the "License");
--  you may not use this file except in compliance with the License.
--  You may obtain a copy of the License at
--
--      http://www.apache.org/licenses/LICENSE-2.0
--
--  Unless required by applicable law or agreed to in writing, software
--  distributed under the License is distributed on an "AS IS" BASIS,
--  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--  See the License for the specific language governing permissions and
--  limitations under the License.
-----------------------------------------------------------------------

with Util.Tests;

package Util.Events.Timers.Tests is

   procedure Add_Tests (Suite : in Util.Tests.Access_Test_Suite);

   type Test is new Util.Tests.Test
     and Util.Events.Timers.Timer with record
      Count : Natural := 0;
   end record;

   overriding
   procedure Time_Handler (Sub   : in out Test;
                           Event : in out Timer_Ref'Class);

   --  Test empty timers.
   procedure Test_Empty_Timer (T : in out Test);

   procedure Test_Timer_Event (T : in out Test);

end Util.Events.Timers.Tests;
