--  Generated by utildgen.c from system includes
with Interfaces.C;
package Util.Systems.Constants is

   pragma Pure;

   --  Flags used when opening a file with open/creat.
   O_RDONLY                      : constant Interfaces.C.int := 8#000000#;
   O_WRONLY                      : constant Interfaces.C.int := 8#000001#;
   O_RDWR                        : constant Interfaces.C.int := 8#000002#;
   O_CREAT                       : constant Interfaces.C.int := 8#001000#;
   O_EXCL                        : constant Interfaces.C.int := 8#004000#;
   O_TRUNC                       : constant Interfaces.C.int := 8#002000#;
   O_APPEND                      : constant Interfaces.C.int := 8#000010#;
   O_CLOEXEC                     : constant Interfaces.C.int := 8#4000000#;
   O_SYNC                        : constant Interfaces.C.int := 8#000200#;
   O_DIRECT                      : constant Interfaces.C.int := 8#200000#;
   O_NONBLOCK                    : constant Interfaces.C.int := 8#000004#;

   --  Some error codes
   EPERM                         : constant := 1;
   ENOENT                        : constant := 2;
   EINTR                         : constant := 4;
   EIO                           : constant := 5;
   ENOEXEC                       : constant := 8;
   EBADF                         : constant := 9;
   EAGAIN                        : constant := 11;
   ENOMEM                        : constant := 12;
   EACCES                        : constant := 13;
   EFAULT                        : constant := 14;
   EBUSY                         : constant := 16;
   EEXIST                        : constant := 17;
   ENOTDIR                       : constant := 20;
   EISDIR                        : constant := 21;
   EINVAL                        : constant := 22;
   ENFILE                        : constant := 23;
   EMFILE                        : constant := 24;
   EFBIG                         : constant := 27;
   ENOSPC                        : constant := 28;
   EROFS                         : constant := 30;
   EPIPE                         : constant := 32;

   --  Flags used by fcntl
   F_SETFL                       : constant Interfaces.C.int := 4;
   F_GETFL                       : constant Interfaces.C.int := 3;
   FD_CLOEXEC                    : constant Interfaces.C.int := 1;

   --  Flags used by dlopen
   RTLD_LAZY                     : constant Interfaces.C.int := 8#000001#;
   RTLD_NOW                      : constant Interfaces.C.int := 8#000002#;
   RTLD_NOLOAD                   : constant Interfaces.C.int := 8#020000#;
   RTLD_DEEPBIND                 : constant Interfaces.C.int := 8#000000#;
   RTLD_GLOBAL                   : constant Interfaces.C.int := 8#000400#;
   RTLD_LOCAL                    : constant Interfaces.C.int := 8#000000#;
   RTLD_NODELETE                 : constant Interfaces.C.int := 8#010000#;

   DLL_OPTIONS   : constant String := "-ldl";
   SYMBOL_PREFIX : constant String := "";

end Util.Systems.Constants;
