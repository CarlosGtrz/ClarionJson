  MAP
    MODULE('BASE64.C')

      ! * Encode buffer src of size slen into dst.
      ! *
      ! * Returns 0 if successful (dlen contains the # of bytes written) or
      ! *         ERR_BASE64_BUFFER_TOO_SMALL if *dlen is not large enough,
      ! *         in which case it is updated to contain the requested size.
      ! *
      ! * You may call this function with dst = NULL to determine how much
      ! * is needed for the destination buffer.
      !
      !int base64_encode( uchar *dst, uint *dlen, uchar *src, uint slen )
      !
      !  res = base64_encode(str64,ulen64,strbin,ulenbin)

      base64_encode (*CSTRING,*ULONG,*STRING,ULONG),SIGNED,RAW,PROC,NAME('_base64_encode')

      ! * Decode buffer src of size slen into dst.
      ! *
      ! * Returns 0 if successful (dlen contains the # of bytes written)
      ! *         ERR_BASE64_INVALID_CHARACTER if an invalid char is found
      ! *         ERR_BASE64_BUFFER_TOO_SMALL if *dlen is not large enough,
      ! *         in which case it is updated to contain the requested size.
      ! *
      ! * You may call this function with dst = NULL to determine how much
      ! * is needed for the destination buffer.
      !
      !int base64_decode( uchar *dst, uint *dlen, uchar *src, uint slen )
      !   res = base64_decode(strbin,ulenbin,str64,LEN(CLIP(str64)))

      base64_decode(*STRING,*ULONG,*STRING,ULONG),LONG,RAW,PROC,NAME('_base64_decode')

    END
  .
  
  PRAGMA ('compile(base64.c)')

ERR_BASE64_INVALID_CHARACTER EQUATE(0002H)
ERR_BASE64_BUFFER_TOO_SMALL EQUATE(0004H)
