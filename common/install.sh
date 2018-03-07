UNSELECTED_MODE=-1
SELINUX_MODE=$UNSELECTED_MODE
case $(basename $ZIP) in
  *permissive*|*Permissive*|*PERMISSIVE*)
    SELINUX_MODE=0
    ;;
  *enforc*|*Enforc*|*ENFORC*)
    SELINUX_MODE=1
    ;;
esac

# Keycheck binary by someone755 @Github, idea for code below by Zappo @xda-developers
# Keycheck binary by someone755 @Github, idea for code below by Zappo @xda-developers
chmod 755 $INSTALLER/common/keycheck

keytest() {
  ui_print "- Vol Key Test -"
  ui_print "   Press Vol Up:"
  (/system/bin/getevent -lc 1 2>&1 | /system/bin/grep VOLUME | /system/bin/grep " DOWN" > $INSTALLER/events) || return 1
  return 0
}

chooseport() {
  #note from chainfire @xda-developers: getevent behaves weird when piped, and busybox grep likes that even less than toolbox/toybox grep
  while (true); do
    /system/bin/getevent -lc 1 2>&1 | /system/bin/grep VOLUME | /system/bin/grep " DOWN" > $INSTALLER/events
    if (`cat $INSTALLER/events 2>/dev/null | /system/bin/grep VOLUME >/dev/null`); then
      break
    fi
  done
  if (`cat $INSTALLER/events 2>/dev/null | /system/bin/grep VOLUMEUP >/dev/null`); then
    return 0
  else
    return 1
  fi
}

chooseportold() {
  # Calling it first time detects previous input. Calling it second time will do what we want
  $INSTALLER/common/keycheck
  $INSTALLER/common/keycheck
  SEL=$?
  if [ "$1" == "UP" ]; then
    UP=$SEL
  elif [ "$1" == "DOWN" ]; then
    DOWN=$SEL
  elif [ $SEL -eq $UP ]; then
    return 0
  elif [ $SEL -eq $DOWN ]; then
    return 1
  else
    ui_print "   Vol key not detected!"
    abort "   Use name change method in TWRP"
  fi
}

if [ $SELINUX_MODE == $UNSELECTED_MODE ]; then
  if keytest; then
    FUNCTION=chooseport
  else
    FUNCTION=chooseportold
    ui_print "   ! Legacy device detected! Using old keycheck method"
    ui_print " "
    ui_print "- Vol Key Programming -"
    ui_print "   Press Vol Up Again:"
    $FUNCTION "UP"
    ui_print "   Press Vol Down"
    $FUNCTION "DOWN"
  fi
  
  ui_print "---Select SELinux Mode---"
  ui_print "  Vol+ = Enforcing"
  ui_print "  Vol- = Permissive"
  if $FUNCTION; then
    SELINUX_MODE=1
    ui_print "SELinux Enforcing Mode selected."
  else
    SELINUX_MODE=0
    ui_print "SELinux Permissive Mode selected."
  fi
else
  ui_print "SELinux Mode specified in filename."
fi

ui_print "Writing SELinux Mode to startup script..."
sed -i "s/<SELINUX_MODE>/$SELINUX_MODE/g" $INSTALLER/common/post-fs-data.sh
