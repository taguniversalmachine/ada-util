-----------------------------------------------------------------------
--  AUnit utils - Helper for writing unit tests
--  Copyright (C) 2009, 2010, 2011, 2012, 2013, 2017, 2019, 2021, 2022 Stephane Carrez
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
with GNAT.Command_Line;
with GNAT.Regpat;
with GNAT.Traceback.Symbolic;

with Ada.Command_Line;
with Ada.Directories;
with Ada.IO_Exceptions;
with Ada.Text_IO;
with Ada.Calendar.Formatting;
with Ada.Exceptions;
with Ada.Containers;

with Util.Strings;
with Util.Measures;
with Util.Files;
with Util.Strings.Vectors;
with Util.Log.Loggers;
package body Util.Tests is

   Test_Properties : Util.Properties.Manager;

   --  When a test uses external test files to match a result against a well
   --  defined content, it can be difficult to maintain those external files.
   --  The <b>Assert_Equal_Files</b> can automatically maintain the reference
   --  file by updating it with the lastest test result.
   --
   --  Of course, using this mode means the test does not validate anything.
   Update_Test_Files : Boolean := False;

   --  The default timeout for a test case execution.
   Default_Timeout   : Duration := 60.0;

   --  A prefix that is added to the test class names.  Adding a prefix is useful when
   --  the same testsuite is executed several times with different configurations.  It allows
   --  to track and identify the tests in different environments and have a global view
   --  in Jenkins.  See option '-p prefix'.
   Harness_Prefix    : Unbounded_String;

   --  Verbose flag activated by the '-v' option.
   Verbose_Flag      : Boolean := False;

   --  When not empty, defines the name of the test that is enabled.  Other tests are disabled.
   --  This is initialized by the -r test option.
   Enabled_Test      : Unbounded_String;

   --  ------------------------------
   --  Get a path to access a test file.
   --  ------------------------------
   function Get_Path (File : String) return String is
      Dir : constant String := Get_Parameter ("test.dir", ".");
   begin
      return Dir & "/" & File;
   end Get_Path;

   --  ------------------------------
   --  Get a path to create a test file.
   --  ------------------------------
   function Get_Test_Path (File : String) return String is
      Dir : constant String := Get_Parameter ("test.result.dir", "regtests/results");
   begin
      return Dir & "/" & File;
   end Get_Test_Path;

   --  ------------------------------
   --  Get the timeout for the test execution.
   --  ------------------------------
   function Get_Test_Timeout (Name : in String) return Duration is
      Prop_Name : constant String := "test.timeout." & Name;
      Value     : constant String := Test_Properties.Get (Prop_Name,
                                                          Duration'Image (Default_Timeout));
   begin
      return Duration'Value (Value);

   exception
      when Constraint_Error =>
         return Default_Timeout;
   end Get_Test_Timeout;

   --  ------------------------------
   --  Get the testsuite harness prefix.  This prefix is added to the test class name.
   --  By default it is empty.  It is allows to execute the test harness on different
   --  environment (ex: MySQL or SQLlite) and be able to merge and collect the two result
   --  sets together.
   --  ------------------------------
   function Get_Harness_Prefix return String is
   begin
      return To_String (Harness_Prefix);
   end Get_Harness_Prefix;

   --  ------------------------------
   --  Get a test configuration parameter.
   --  ------------------------------
   function Get_Parameter (Name    : String;
                           Default : String := "") return String is
   begin
      return Test_Properties.Get (Name, Default);
   end Get_Parameter;

   --  ------------------------------
   --  Get the test configuration properties.
   --  ------------------------------
   function Get_Properties return Util.Properties.Manager is
   begin
      return Test_Properties;
   end Get_Properties;

   --  ------------------------------
   --  Get a new unique string
   --  ------------------------------
   function Get_Uuid return String is
      Time  : constant Ada.Calendar.Time := Ada.Calendar.Clock;
      Year  : Ada.Calendar.Year_Number;
      Month : Ada.Calendar.Month_Number;
      Day   : Ada.Calendar.Day_Number;
      T     : Ada.Calendar.Day_Duration;
      V     : Long_Long_Integer;
   begin
      Ada.Calendar.Split (Date    => Time,
                          Year    => Year,
                          Month   => Month,
                          Day     => Day,
                          Seconds => T);
      V := (Long_Long_Integer (Year) * 365 * 24 * 3600 * 1000)
        + (Long_Long_Integer (Month) * 31 * 24 * 3600 * 1000)
        + (Long_Long_Integer (Day) * 24 * 3600 * 1000)
        + (Long_Long_Integer (T * 1000));
      return "U" & Util.Strings.Image (V);
   end Get_Uuid;

   --  ------------------------------
   --  Get the verbose flag that can be activated with the <tt>-v</tt> option.
   --  ------------------------------
   function Verbose return Boolean is
   begin
      return Verbose_Flag;
   end Verbose;

   --  ------------------------------
   --  Returns True if the test with the given name is enabled.
   --  By default all the tests are enabled.  When the -r test option is passed
   --  all the tests are disabled except the test specified by the -r option.
   --  ------------------------------
   function Is_Test_Enabled (Name : in String) return Boolean is
   begin
      return Length (Enabled_Test) = 0 or else Enabled_Test = Name;
   end Is_Test_Enabled;

   --  ------------------------------
   --  Check that the value matches what we expect.
   --  ------------------------------
   procedure Assert_Equals (T         : in Test'Class;
                            Expect, Value : in Ada.Calendar.Time;
                            Message   : in String := "Test failed";
                            Source    : String := GNAT.Source_Info.File;
                            Line      : Natural := GNAT.Source_Info.Line) is
      use Ada.Calendar.Formatting;
      use Ada.Calendar;
   begin
      T.Assert (Condition => Image (Expect) = Image (Value),
                Message   => Message & ": expecting '" & Image (Expect) & "'"
                & " value was '" & Image (Value) & "'",
                Source    => Source,
                Line      => Line);
   end Assert_Equals;

   --  ------------------------------
   --  Check that the value matches what we expect.
   --  ------------------------------
   procedure Assert_Equals (T         : in Test'Class;
                            Expect, Value : in String;
                            Message   : in String := "Test failed";
                            Source    : String := GNAT.Source_Info.File;
                            Line      : Natural := GNAT.Source_Info.Line) is
   begin
      T.Assert (Condition => Expect = Value,
                Message   => Message & ": expecting '" & Expect & "'"
                & " value was '" & Value & "'",
                Source    => Source,
                Line      => Line);
   end Assert_Equals;

   --  ------------------------------
   --  Check that the value matches what we expect.
   --  ------------------------------
   procedure Assert_Equals (T       : in Test'Class;
                            Expect  : in String;
                            Value   : in Unbounded_String;
                            Message : in String := "Test failed";
                            Source  : String := GNAT.Source_Info.File;
                            Line    : Natural := GNAT.Source_Info.Line) is
   begin
      Assert_Equals (T      => T,
                     Expect => Expect,
                     Value  => To_String (Value),
                     Message => Message,
                     Source  => Source,
                     Line    => Line);
   end Assert_Equals;

   --  ------------------------------
   --  Check that the value matches the regular expression
   --  ------------------------------
   procedure Assert_Matches (T       : in Test'Class;
                             Pattern : in String;
                             Value   : in Unbounded_String;
                             Message : in String := "Test failed";
                             Source  : String := GNAT.Source_Info.File;
                             Line    : Natural := GNAT.Source_Info.Line) is
   begin
      Assert_Matches (T       => T,
                      Pattern => Pattern,
                      Value   => To_String (Value),
                      Message => Message,
                      Source  => Source,
                      Line    => Line);
   end Assert_Matches;

   --  ------------------------------
   --  Check that the value matches the regular expression
   --  ------------------------------
   procedure Assert_Matches (T       : in Test'Class;
                             Pattern : in String;
                             Value   : in String;
                             Message : in String := "Test failed";
                             Source  : String := GNAT.Source_Info.File;
                             Line    : Natural := GNAT.Source_Info.Line) is
      use GNAT.Regpat;

      Regexp  : constant Pattern_Matcher := Compile (Expression => Pattern,
                                                     Flags      => Multiple_Lines);
   begin
      T.Assert (Condition => Match (Regexp, Value),
                Message   => Message & ". Value '" & Value & "': Does not Match '"
                & Pattern & "'",
                Source    => Source,
                Line      => Line);
   end Assert_Matches;

   --  ------------------------------
   --  Check that the file exists.
   --  ------------------------------
   procedure Assert_Exists (T        : in Test'Class;
                            File     : in String;
                            Message : in String := "Test failed";
                            Source  : String := GNAT.Source_Info.File;
                            Line    : Natural := GNAT.Source_Info.Line) is
   begin
      T.Assert (Condition => Ada.Directories.Exists (File),
                Message   => Message & ": file '" & File & "' does not exist",
                Source    => Source,
                Line      => Line);
   end Assert_Exists;

   --  ------------------------------
   --  Check that two files are equal.  This is intended to be used by
   --  tests that create files that are then checked against patterns.
   --  ------------------------------
   procedure Assert_Equal_Files (T       : in Test_Case'Class;
                                 Expect  : in String;
                                 Test    : in String;
                                 Message : in String := "Test failed";
                                 Source  : String := GNAT.Source_Info.File;
                                 Line    : Natural := GNAT.Source_Info.Line) is
      use Util.Files;
      use type Ada.Containers.Count_Type;
      use type Util.Strings.Vectors.Vector;

      Expect_File : Util.Strings.Vectors.Vector;
      Test_File   : Util.Strings.Vectors.Vector;
      Same        : Boolean;
   begin
      begin
         if not Ada.Directories.Exists (Expect) then
            T.Assert (Condition => False,
                      Message => "Expect file '" & Expect & "' does not exist",
                      Source  => Source, Line => Line);
         end if;
         Read_File (Path => Expect,
                    Into => Expect_File);
         Read_File (Path => Test,
                    Into => Test_File);

      exception
         when others =>
            if Update_Test_Files then
               Ada.Directories.Copy_File (Source_Name => Test,
                                          Target_Name => Expect);
            else
               raise;
            end if;
      end;

      if Expect_File.Length /= Test_File.Length then
         if Update_Test_Files then
            Ada.Directories.Copy_File (Source_Name => Test,
                                       Target_Name => Expect);
         end if;

         --  Check file sizes
         Assert_Equals (T       => T,
                        Expect  => Natural (Expect_File.Length),
                        Value   => Natural (Test_File.Length),
                        Message => Message & ": Invalid number of lines",
                        Source  => Source,
                        Line    => Line);
      end if;

      Same := Expect_File = Test_File;
      if Same then
         return;
      end if;
      if Update_Test_Files then
         Ada.Directories.Copy_File (Source_Name => Test,
                                    Target_Name => Expect);
      end if;
      T.Assert (Condition => False,
                Message   => Message & ": Content is different on some lines",
                Source    => Source,
                Line      => Line);
   end Assert_Equal_Files;

   --  ------------------------------
   --  Check that two files are equal.  This is intended to be used by
   --  tests that create files that are then checked against patterns.
   --  ------------------------------
   procedure Assert_Equal_Files (T       : in Test'Class;
                                 Expect  : in String;
                                 Test    : in String;
                                 Message : in String := "Test failed";
                                 Source  : String := GNAT.Source_Info.File;
                                 Line    : Natural := GNAT.Source_Info.Line) is
      use Util.Files;
      use type Ada.Containers.Count_Type;
      use type Util.Strings.Vectors.Vector;

      Expect_File : Util.Strings.Vectors.Vector;
      Test_File   : Util.Strings.Vectors.Vector;
      Same        : Boolean;
   begin
      begin
         if not Ada.Directories.Exists (Expect) then
            T.Assert (Condition => False,
                      Message => "Expect file '" & Expect & "' does not exist",
                      Source  => Source, Line => Line);
         end if;
         Read_File (Path => Expect,
                    Into => Expect_File);
         Read_File (Path => Test,
                    Into => Test_File);

      exception
         when others =>
            if Update_Test_Files then
               Ada.Directories.Copy_File (Source_Name => Test,
                                          Target_Name => Expect);
            else
               raise;
            end if;
      end;

      if Expect_File.Length /= Test_File.Length then
         if Update_Test_Files then
            Ada.Directories.Copy_File (Source_Name => Test,
                                       Target_Name => Expect);
         end if;

         --  Check file sizes
         Assert_Equals (T       => T,
                        Expect  => Natural (Expect_File.Length),
                        Value   => Natural (Test_File.Length),
                        Message => Message & ": Invalid number of lines",
                        Source  => Source,
                        Line    => Line);
      end if;

      Same := Expect_File = Test_File;
      if Same then
         return;
      end if;
      if Update_Test_Files then
         Ada.Directories.Copy_File (Source_Name => Test,
                                    Target_Name => Expect);
      end if;
      Fail (T       => T,
            Message => Message & ": Content is different on some lines",
            Source  => Source,
            Line    => Line);
   end Assert_Equal_Files;

   --  ------------------------------
   --  Report a test failed.
   --  ------------------------------
   procedure Fail (T       : in Test'Class;
                   Message : in String := "Test failed";
                   Source  : in String := GNAT.Source_Info.File;
                   Line    : in Natural := GNAT.Source_Info.Line) is
   begin
      T.Assert (False, Message, Source, Line);
   end Fail;

   --  ------------------------------
   --  Default initialization procedure.
   --  ------------------------------
   procedure Initialize_Test (Props : in Util.Properties.Manager) is
   begin
      null;
   end Initialize_Test;

   --  ------------------------------
   --  The main testsuite program.  This launches the tests, collects the
   --  results, create performance logs and set the program exit status
   --  according to the testsuite execution status.
   --
   --  The <b>Initialize</b> procedure is called before launching the unit tests.  It is intended
   --  to configure the tests according to some external environment (paths, database access).
   --
   --  The <b>Finish</b> procedure is called after the test suite has executed.
   --  ------------------------------
   procedure Harness (Name : in String) is
      use GNAT.Command_Line;
      use Ada.Text_IO;
      use type Util.XUnit.Status;

      procedure Help;

      procedure Help is
      begin
         Put_Line ("Test harness: " & Name);
         Put ("Usage: harness [-l label] [-xml result.xml] [-t timeout] [-p prefix] [-v]"
              & "[-config file.properties] [-d dir] [-r testname]");
         Put_Line ("[-update]");
         Put_Line ("-l label       Print the label in the test summary result");
         Put_Line ("-xml file      Produce an XML test report");
         Put_Line ("-config file   Specify a test configuration file");
         Put_Line ("-d dir         Change the current directory to <dir>");
         Put_Line ("-t timeout     Test execution timeout in seconds");
         Put_Line ("-v             Activate the verbose test flag");
         Put_Line ("-p prefix      Add the prefix to the test class names");
         Put_Line ("-r testname    Run only the tests for the given testsuite name");
         Put_Line ("-update        Update the test reference files if a file");
         Put_Line ("               is missing or the test generates another output");
         Put_Line ("               (See Assert_Equals_File)");
         Ada.Command_Line.Set_Exit_Status (2);
      end Help;

      Perf      : aliased Util.Measures.Measure_Set;
      Result    : Util.XUnit.Status;
      XML       : Boolean := False;
      Output    : Ada.Strings.Unbounded.Unbounded_String;
      Chdir     : Ada.Strings.Unbounded.Unbounded_String;
      Label     : String (1 .. 16) := (others => ' ');
   begin
      loop
         case Getopt ("h u v l: x: t: p: c: config: d: r: update help xml: timeout:") is
            when ASCII.NUL =>
               exit;

            when 'c' =>
               declare
                  Name : constant String := Parameter;
               begin
                  Test_Properties.Load_Properties (Name);

                  Default_Timeout := Get_Test_Timeout ("default");

               exception
                  when Ada.IO_Exceptions.Name_Error =>
                     Ada.Text_IO.Put_Line ("Cannot find configuration file: " & Name);
                     Ada.Command_Line.Set_Exit_Status (2);
                     return;
               end;

            when 'd' =>
               Chdir := To_Unbounded_String (Parameter);

            when 'l' =>
               if Parameter'Length > Label'Length then
                  Label := Parameter (Parameter'First .. Parameter'First + Label'Length - 1);
               else
                  Label := (others => ' ');
                  Label (Label'First .. Label'First + Parameter'Length - 1) := Parameter;
               end if;

            when 'u' =>
               Update_Test_Files := True;

            when 't' =>
               begin
                  Default_Timeout := Duration'Value (Parameter);

               exception
                  when Constraint_Error =>
                     Ada.Text_IO.Put_Line ("Invalid timeout: " & Parameter);
                     Ada.Command_Line.Set_Exit_Status (2);
                     return;
               end;

            when 'r' =>
               Enabled_Test := To_Unbounded_String (Parameter);

            when 'p' =>
               Harness_Prefix := To_Unbounded_String (Parameter & " ");

            when 'v' =>
               Verbose_Flag := True;

            when 'x' =>
               XML := True;
               Output := To_Unbounded_String (Parameter);

            when others =>
               Help;
               return;
         end case;
      end loop;

      --  Initialization is optional.  Get the log configuration by reading the property
      --  file 'samples/log4j.properties'.  The 'log.util' logger will use a DEBUG level
      --  and write the message in 'result.log'.
      Util.Log.Loggers.Initialize (Test_Properties);

      Initialize (Test_Properties);

      if Length (Chdir) /= 0 then
         begin
            Ada.Directories.Set_Directory (To_String (Chdir));

         exception
            when Ada.IO_Exceptions.Name_Error =>
               Put_Line ("Invalid directory " & To_String (Chdir));
               Ada.Command_Line.Set_Exit_Status (1);
               return;
         end;
      end if;
      declare

         procedure Runner is new Util.XUnit.Harness (Suite);

         S  : Util.Measures.Stamp;
      begin
         Util.Measures.Set_Current (Perf'Unchecked_Access);
         Runner (To_String (Output), XML,
                 (if (for all C of Label => C = ' ') then "" else Label), Result);
         Util.Measures.Report (Perf, S, "Testsuite execution");
         Util.Measures.Write (Perf, "Test measures", Name);
      end;

      Finish (Result);

      --  Program exit status reflects the testsuite result
      if Result /= Util.XUnit.Success then
         Ada.Command_Line.Set_Exit_Status (1);
      else
         Ada.Command_Line.Set_Exit_Status (0);
      end if;

   exception
      when Invalid_Switch =>
         Put_Line ("Invalid Switch " & Full_Switch);
         Help;
         return;

      when Invalid_Parameter =>
         Put_Line ("No parameter for " & Full_Switch);
         Help;
         return;

      when E : others =>
         Put_Line ("Exception: " & Ada.Exceptions.Exception_Name (E));
         Put_Line ("Message:   " & Ada.Exceptions.Exception_Message (E));
         Put_Line ("Stacktrace:");
         Put_Line (GNAT.Traceback.Symbolic.Symbolic_Traceback (E));
         Ada.Command_Line.Set_Exit_Status (4);

   end Harness;

end Util.Tests;
