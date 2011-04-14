-----------------------------------------------------------------------
--  util-serialize-io-xml -- XML Serialization Driver
--  Copyright (C) 2011 Stephane Carrez
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

with Unicode;
with Unicode.CES.Utf8;

with Ada.Exceptions;
with Util.Log.Loggers;
package body Util.Serialize.IO.XML is

   use Util.Log;
   use Sax.Readers;
   use Sax.Exceptions;
   use Sax.Locators;
   use Sax.Attributes;
   use Unicode;
   use Unicode.CES;
   use Ada.Strings.Unbounded;

   --  The logger
   Log : constant Loggers.Logger := Loggers.Create ("Util.Serialize.IO.XML");

   procedure Push (Handler : in out Xhtml_Reader'Class);
   procedure Pop (Handler  : in out Xhtml_Reader'Class);

   --  ------------------------------
   --  Push the current context when entering in an element.
   --  ------------------------------
   procedure Push (Handler : in out Xhtml_Reader'Class) is
   begin
--        if Handler.Stack = null then
--           Handler.Stack := new Element_Context_Array (1 .. 100);
--        elsif Handler.Stack_Pos = Handler.Stack'Last then
--           declare
--              Old : Element_Context_Array_Access := Handler.Stack;
--           begin
--              Handler.Stack := new Element_Context_Array (1 .. Old'Last + 100);
--              Handler.Stack (1 .. Old'Last) := Old (1 .. Old'Last);
--              Free (Old);
--           end;
--        end if;
--        if Handler.Stack_Pos /= Handler.Stack'First then
--           Handler.Stack (Handler.Stack_Pos + 1) := Handler.Stack (Handler.Stack_Pos);
--        end if;
--        Handler.Stack_Pos := Handler.Stack_Pos + 1;
--        Handler.Current := Handler.Stack (Handler.Stack_Pos)'Access;
      null;
   end Push;

   --  ------------------------------
   --  Pop the context and restore the previous context when leaving an element
   --  ------------------------------
   procedure Pop (Handler  : in out Xhtml_Reader'Class) is
   begin
--        Handler.Stack_Pos := Handler.Stack_Pos - 1;
--        Handler.Current := Handler.Stack (Handler.Stack_Pos)'Access;
      null;
   end Pop;

   --  ------------------------------
   --  Warning
   --  ------------------------------
   overriding
   procedure Warning (Handler : in out Xhtml_Reader;
                      Except  : Sax.Exceptions.Sax_Parse_Exception'Class) is
      pragma Warnings (Off, Handler);
   begin
      Log.Warn ("{0}: {1}", To_String (Get_Locator (Except)), Get_Message (Except));
   end Warning;

   --  ------------------------------
   --  Error
   --  ------------------------------
   overriding
   procedure Error (Handler : in out Xhtml_Reader;
                    Except  : in Sax.Exceptions.Sax_Parse_Exception'Class) is
      pragma Warnings (Off, Handler);
   begin
      Log.Error ("{0}: {1}", To_String (Get_Locator (Except)), Get_Message (Except));
   end Error;

   --  ------------------------------
   --  Fatal_Error
   --  ------------------------------
   overriding
   procedure Fatal_Error (Handler : in out Xhtml_Reader;
                          Except  : in Sax.Exceptions.Sax_Parse_Exception'Class) is
      pragma Unreferenced (Handler);
   begin
      Log.Error ("{0}: {1}", To_String (Get_Locator (Except)), Get_Message (Except));
   end Fatal_Error;

   --  ------------------------------
   --  Set_Document_Locator
   --  ------------------------------
   overriding
   procedure Set_Document_Locator (Handler : in out Xhtml_Reader;
                                   Loc     : in out Sax.Locators.Locator) is
   begin
      Handler.Locator := Loc;
   end Set_Document_Locator;

   --  ------------------------------
   --  Start_Document
   --  ------------------------------
   overriding
   procedure Start_Document (Handler : in out Xhtml_Reader) is
   begin
      null;
   end Start_Document;

   --  ------------------------------
   --  End_Document
   --  ------------------------------
   overriding
   procedure End_Document (Handler : in out Xhtml_Reader) is
   begin
      null;
   end End_Document;

   --  ------------------------------
   --  Start_Prefix_Mapping
   --  ------------------------------
   overriding
   procedure Start_Prefix_Mapping (Handler : in out Xhtml_Reader;
                                   Prefix  : in Unicode.CES.Byte_Sequence;
                                   URI     : in Unicode.CES.Byte_Sequence) is
   begin
      null;
   end Start_Prefix_Mapping;

   --  ------------------------------
   --  End_Prefix_Mapping
   --  ------------------------------
   overriding
   procedure End_Prefix_Mapping (Handler : in out Xhtml_Reader;
                                 Prefix  : in Unicode.CES.Byte_Sequence) is
   begin
      null;
   end End_Prefix_Mapping;

   --  ------------------------------
   --  Start_Element
   --  ------------------------------
   overriding
   procedure Start_Element (Handler       : in out Xhtml_Reader;
                            Namespace_URI : in Unicode.CES.Byte_Sequence := "";
                            Local_Name    : in Unicode.CES.Byte_Sequence := "";
                            Qname         : in Unicode.CES.Byte_Sequence := "";
                            Atts          : in Sax.Attributes.Attributes'Class) is
      pragma Unreferenced (Namespace_URI, Qname);

      use Ada.Exceptions;

      Attr_Count : Natural;
   begin
--        Handler.Line.Line   := Sax.Locators.Get_Line_Number (Handler.Locator);
--        Handler.Line.Column := Sax.Locators.Get_Column_Number (Handler.Locator);

      --  Push the current context to keep track where we are.
      Push (Handler);
      Log.Debug ("Start object {0}", Local_Name);

      Handler.Handler.Start_Object (Local_Name);
      Attr_Count := Get_Length (Atts);
      begin
         for I in 0 .. Attr_Count - 1 loop
            declare
               Name  : constant String := Get_Qname (Atts, I);
               Value : constant String := Get_Value (Atts, I);
            begin
               Handler.Handler.Set_Member (Name      => Name,
                                           Value     => Util.Beans.Objects.To_Object (Value),
                                           Attribute => True);
            end;
         end loop;

      exception
         when others =>
            raise;
      end;
   end Start_Element;

   --  ------------------------------
   --  End_Element
   --  ------------------------------
   overriding
   procedure End_Element (Handler       : in out Xhtml_Reader;
                          Namespace_URI : in Unicode.CES.Byte_Sequence := "";
                          Local_Name    : in Unicode.CES.Byte_Sequence := "";
                          Qname         : in Unicode.CES.Byte_Sequence := "") is
      pragma Unreferenced (Namespace_URI, Qname);
   begin
      --  Pop the current context to restore the last context.
      Pop (Handler);
      Handler.Handler.Finish_Object (Local_Name);
      if Length (Handler.Text) > 0 then
         Log.Debug ("Close object {0} -> {1}", Local_Name, To_String (Handler.Text));
         Handler.Handler.Set_Member (Local_Name, Util.Beans.Objects.To_Object (Handler.Text));
         Set_Unbounded_String (Handler.Text, "");
      else
         Log.Debug ("Close object {0}", Local_Name);
      end if;
   end End_Element;

   procedure Collect_Text (Handler : in out Xhtml_Reader;
                           Content : Unicode.CES.Byte_Sequence) is
   begin
      Append (Handler.Text, Content);
   end Collect_Text;

   --  ------------------------------
   --  Characters
   --  ------------------------------
   overriding
   procedure Characters (Handler : in out Xhtml_Reader;
                         Ch      : in Unicode.CES.Byte_Sequence) is
   begin
      Collect_Text (Handler, Ch);
   end Characters;

   --  ------------------------------
   --  Ignorable_Whitespace
   --  ------------------------------
   overriding
   procedure Ignorable_Whitespace (Handler : in out Xhtml_Reader;
                                   Ch      : in Unicode.CES.Byte_Sequence) is
   begin
      if not Handler.Ignore_White_Spaces then
         Collect_Text (Handler, Ch);
      end if;
   end Ignorable_Whitespace;

   --  ------------------------------
   --  Processing_Instruction
   --  ------------------------------
   overriding
   procedure Processing_Instruction (Handler : in out Xhtml_Reader;
                                     Target  : in Unicode.CES.Byte_Sequence;
                                     Data    : in Unicode.CES.Byte_Sequence) is
      pragma Unmodified (Handler);
   begin
      Log.Error ("Processing instruction: {0}: {1}", Target, Data);
   end Processing_Instruction;

   --  ------------------------------
   --  Skipped_Entity
   --  ------------------------------
   overriding
   procedure Skipped_Entity (Handler : in out Xhtml_Reader;
                             Name    : in Unicode.CES.Byte_Sequence) is
      pragma Unmodified (Handler);
   begin
      null;
   end Skipped_Entity;

   --  ------------------------------
   --  Start_Cdata
   --  ------------------------------
   overriding
   procedure Start_Cdata (Handler : in out Xhtml_Reader) is
      pragma Unmodified (Handler);
   begin
      Log.Info ("Start CDATA");
   end Start_Cdata;

   --  ------------------------------
   --  End_Cdata
   --  ------------------------------
   overriding
   procedure End_Cdata (Handler : in out Xhtml_Reader) is
      pragma Unmodified (Handler);
   begin
      Log.Info ("End CDATA");
   end End_Cdata;

   --  ------------------------------
   --  Resolve_Entity
   --  ------------------------------
   overriding
   function Resolve_Entity (Handler   : Xhtml_Reader;
                            Public_Id : Unicode.CES.Byte_Sequence;
                            System_Id : Unicode.CES.Byte_Sequence)
                            return Input_Sources.Input_Source_Access is
      pragma Unreferenced (Handler);
   begin
      Log.Error ("Cannot resolve entity {0} - {1}", Public_Id, System_Id);
      return null;
   end Resolve_Entity;

   overriding
   procedure Start_DTD (Handler   : in out Xhtml_Reader;
                        Name      : Unicode.CES.Byte_Sequence;
                        Public_Id : Unicode.CES.Byte_Sequence := "";
                        System_Id : Unicode.CES.Byte_Sequence := "") is
   begin
      null;
   end Start_DTD;

   --  ------------------------------
   --  Set the XHTML reader to ignore or not the white spaces.
   --  When set to True, the ignorable white spaces will not be kept.
   --  ------------------------------
   procedure Set_Ignore_White_Spaces (Reader : in out Parser;
                                      Value  : in Boolean) is
   begin
      Reader.Ignore_White_Spaces := Value;
   end Set_Ignore_White_Spaces;

   --  ------------------------------
   --  Set the XHTML reader to ignore empty lines.
   --  ------------------------------
   procedure Set_Ignore_Empty_Lines (Reader : in out Parser;
                                     Value  : in Boolean) is
   begin
      Reader.Ignore_Empty_Lines := Value;
   end Set_Ignore_Empty_Lines;

   --  ------------------------------
   --  Parse an XML stream, and calls the appropriate SAX callbacks for each
   --  event.
   --  This is not re-entrant: you can not call Parse with the same Parser
   --  argument in one of the SAX callbacks. This has undefined behavior.
   --  ------------------------------

   --  Parse the stream using the JSON parser.
   procedure Parse (Handler : in out Parser;
                    Stream  : in out Util.Streams.Buffered.Buffered_Stream'Class) is

      type String_Access is access all String (1 .. 32);

      type Stream_Input is new Input_Sources.Input_Source with record
         Index    : Natural;
         Last     : Natural;
         Encoding : Unicode.CES.Encoding_Scheme;
         Buffer   : String_Access;
      end record;

      --  Return the next character in the string.
      procedure Next_Char (From : in out Stream_Input;
                           C    : out Unicode.Unicode_Char);

      --  True if From is past the last character in the string.
      function Eof (From : in Stream_Input) return Boolean;
      procedure Fill (From : in out Stream_Input);

      procedure Fill (From : in out Stream_Input) is
      begin
         --  Move to the buffer start
         if From.Last > From.Index and From.Index > From.Buffer'First then
            From.Buffer (From.Buffer'First .. From.Last - 1 - From.Index + From.Buffer'First) :=
              From.Buffer (From.Index .. From.Last - 1);
            From.Last  := From.Last - From.Index + From.Buffer'First;
            From.Index := From.Buffer'First;
         end if;
         if From.Index > From.Last then
            From.Index := From.Buffer'First;
         end if;
         begin
            loop
               Stream.Read (From.Buffer (From.Last));
               From.Last := From.Last + 1;
               exit when From.Last > From.Buffer'Last;
            end loop;
         exception
            when others =>
               null;
         end;
      end Fill;

      --  Return the next character in the string.
      procedure Next_Char (From : in out Stream_Input;
                           C    : out Unicode.Unicode_Char) is
      begin
         if From.Index + 6 >= From.Last then
            Fill (From);
         end if;
         From.Encoding.Read (From.Buffer.all, From.Index, C);
--           Log.Info ("Read => " & Character'Val (Unicode.Unicode_Char'Pos (C))); --  Unicode.Unicode_Char'Image (C));
      end Next_Char;

      --  True if From is past the last character in the string.
      function Eof (From : in Stream_Input) return Boolean is
      begin
         if From.Index < From.Last then
            return False;
         end if;
         return Stream.Is_Eof;
      end Eof;

      Input      : Stream_Input;
      Xml_Parser : Xhtml_Reader;
      Buf        : aliased String (1 .. 32);
   begin
      Input.Buffer := Buf'Access;
      Input.Index  := 2;
      Input.Last   := 1;
      Input.Set_Encoding (Unicode.CES.Utf8.Utf8_Encoding);
      Input.Encoding := Unicode.CES.Utf8.Utf8_Encoding;
      Xml_Parser.Handler := Handler'Unchecked_Access;
      Xml_Parser.Ignore_White_Spaces := Handler.Ignore_White_Spaces;
      Xml_Parser.Ignore_Empty_Lines  := Handler.Ignore_Empty_Lines;
      Sax.Readers.Reader (Xml_Parser).Parse (Input);

   exception
      when others =>
--           Free (Parser.Stack);
         raise;
   end Parse;

end Util.Serialize.IO.XML;
