function yawPitchRoll = parse_OSC_yawPitchRoll(bytes)
  % Parse a osc message of yaw, pitch, roll data from the supperware
  % headtracker.
  %
  % Modified by Thomas Deppisch, based on CNMAT OSC parser:
  % Title: Matlab code to parse an OSC message into a vector of floats
  % Author: Contributors to opensoundcontrol.org https://github.com/CNMAT/OpenSoundControl.org/blob/master/contributors.txt
  % Source: https://github.com/CNMAT/OpenSoundControl.org/blob/master/matlab-parse_message.md
  % License: CC BY 4.0
  %
  % Probably by Matt Wright, circa 2012. Courtesy of Karl Yerkes.
  %
  % Parse a single OSC message whose arguments are all floats,
  % returning a matlab string for the address and a vector of floats
  % for the arguments
  yawPitchRoll = nan(3,1);

  numBytesPerArg = 4;

  firstnull = find(bytes==0,1);

  if isempty(firstnull) 
    disp(['Invalid OSC message (no null character = no string = no address)']);
    return
  end

  % zero vs one origin indicing meets OSC's possible extra null characters
  % to bring all strings up to a multiple of 4-byte length
  lastnullafteraddress = firstnull + 3 - mod(firstnull-1, 4);

  for i=firstnull:lastnullafteraddress
    if bytes(i) ~= 0
      disp(['Invalid OSC message (improper string termination)'])
      return
    end
  end

  message = char(bytes(1:firstnull-1)');

  % Got the message, now throw away those bytes
  bytes = bytes(lastnullafteraddress+1:end);
  firstnull = find(bytes==0,1);

  if isempty(firstnull)
    disp(['Invalid OSC message (missing type tag string?)']);
    return
  end
  % zero vs one origin indicing meets OSC's possible extra null characters
  % to bring all strings up to a multiple of 4-byte length
  lastnullaftertypetags = firstnull + 3 - mod(firstnull-1, 4);

  for i=firstnull:lastnullaftertypetags
    if bytes(i) ~= 0
      disp(['Invalid OSC message (typetag has improper string termination)'])
      return
    end
  end

  typetags = char(bytes(1:firstnull-1));
  bytes = bytes(lastnullaftertypetags+1:end);

  if typetags(1) ~= ','
    disp(['Invalid OSC message (type tag string needs leading comma)']);
    return
  end

  if ~all(typetags(2:end) == 'f')
    disp(['Sorry; I only handle floating point arguments, not ' typetags]);
    return
  end  

  % big->little endian and interpret bytes as 32-bit float
  f = typecast(uint8(bytes(numBytesPerArg:-1:1)),'single');
  %f = typecast(uint8(bytes(1:numBytesPerArg)),'single');


  switch message
      case '/yaw'
        yawPitchRoll(1) = f;
      case '/pitch'
        yawPitchRoll(2) = f;
      case '/roll'
        yawPitchRoll(3) = f;
      otherwise
        warning('invalid message')
  end

end