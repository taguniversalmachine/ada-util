-----------------------------------------------------------------------
--  util-encoders-hmac-sha1 -- Compute HMAC-SHA1 authentication code
--  Copyright (C) 2011, 2012, 2017, 2019, 2022 Stephane Carrez
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
with Ada.Streams;
with Ada.Finalization;
with Util.Encoders.SHA1;

--  The <b>Util.Encodes.HMAC.SHA1</b> package generates HMAC-SHA1 authentication
--  (See RFC 2104 - HMAC: Keyed-Hashing for Message Authentication).
package Util.Encoders.HMAC.SHA1 is

   pragma Preelaborate;

   --  Sign the data string with the key and return the HMAC-SHA1 code in binary.
   function Sign (Key  : in String;
                  Data : in String) return Util.Encoders.SHA1.Hash_Array;

   --  Sign the data string with the key and return the HMAC-SHA1 code as hexadecimal string.
   function Sign (Key  : in String;
                  Data : in String) return Util.Encoders.SHA1.Digest;

   --  Sign the data array with the key and return the HMAC-SHA256 code in the result.
   procedure Sign (Key    : in Ada.Streams.Stream_Element_Array;
                   Data   : in Ada.Streams.Stream_Element_Array;
                   Result : out Util.Encoders.SHA1.Hash_Array);

   --  Sign the data string with the key and return the HMAC-SHA1 code as base64 string.
   --  When <b>URL</b> is True, use the base64 URL alphabet to encode in base64.
   function Sign_Base64 (Key  : in String;
                         Data : in String;
                         URL  : in Boolean := False) return Util.Encoders.SHA1.Base64_Digest;

   --  ------------------------------
   --  HMAC-SHA1 Context
   --  ------------------------------
   type Context is limited private;

   --  Set the hmac private key.  The key must be set before calling any <b>Update</b>
   --  procedure.
   procedure Set_Key (E   : in out Context;
                      Key : in String);

   --  Set the hmac private key.  The key must be set before calling any <b>Update</b>
   --  procedure.
   procedure Set_Key (E   : in out Context;
                      Key : in Ada.Streams.Stream_Element_Array);

   --  Update the hash with the string.
   procedure Update (E : in out Context;
                     S : in String);

   --  Update the hash with the string.
   procedure Update (E : in out Context;
                     S : in Ada.Streams.Stream_Element_Array);

   --  Computes the HMAC-SHA1 with the private key and the data collected by
   --  the <b>Update</b> procedures.  Returns the raw binary hash in <b>Hash</b>.
   procedure Finish (E    : in out Context;
                     Hash : out Util.Encoders.SHA1.Hash_Array);

   --  Computes the HMAC-SHA1 with the private key and the data collected by
   --  the <b>Update</b> procedures.  Returns the hexadecimal hash in <b>Hash</b>.
   procedure Finish (E    : in out Context;
                     Hash : out Util.Encoders.SHA1.Digest);

   --  Computes the HMAC-SHA1 with the private key and the data collected by
   --  the <b>Update</b> procedures.  Returns the base64 hash in <b>Hash</b>.
   --  When <b>URL</b> is True, use the base64 URL alphabet to encode in base64.
   procedure Finish_Base64 (E    : in out Context;
                            Hash : out Util.Encoders.SHA1.Base64_Digest;
                            URL  : in Boolean := False);

private

   type Context is new Ada.Finalization.Limited_Controlled with record
      SHA     : Util.Encoders.SHA1.Context;
      Key     : Ada.Streams.Stream_Element_Array (0 .. 63);
      Key_Len : Ada.Streams.Stream_Element_Offset;
   end record;

   --  Initialize the SHA-1 context.
   overriding
   procedure Initialize (E : in out Context);

end Util.Encoders.HMAC.SHA1;
