#!/sbin/sh

##########################################################################################
#
# Installer Script
#
##########################################################################################

SKIPMOUNT=false

PROPFILE=false

POSTFSDATA=false

LATESTARTSERVICE=false

REPLACE_EXAMPLE="
/system/app/Youtube
/system/priv-app/SystemUI
/system/priv-app/Settings
/system/framework
"

REPLACE="
"

print_modname() {
  ui_print ""
  ui_print "  |=============================|"
  ui_print "  |  WhatsApp Emoji Unicode 15  |"
  ui_print "  |=============================|"
  ui_print ""
}

on_install() {
  #Definitions
  MSG_DIR="/data/data/com.facebook.orca"
  FB_DIR="/data/data/com.facebook.katana"
  COMBAT_DIRS="/data/data/com.google.android.gms/files/fonts/opentype /data/user/0/com.google.android.gms/files/fonts/opentype /data_mirror/data_ce/null/0/com.google.android.gms/files/fonts/opentype"
  COMBAT_FONT="Noto_COLR_Emoji_Compat-400-100_0-0_0.ttf"
  EMOJI_DIR="app_ras_blobs"
  FONT_DIR=$MODPATH/system/fonts
  FONT_EMOJI="NotoColorEmoji.ttf"
  ui_print "  Extracting module files"
  ui_print ""
  unzip -o "$ZIPFILE" 'system/*' -d $MODPATH >&2
  ui_print "  Installing Emojis:"

  #Compatibility with different devices and Support for Android 13
  variants='SamsungColorEmoji.ttf LGNotoColorEmoji.ttf HTC_ColorEmoji.ttf AndroidEmoji-htc.ttf AndroidEmoji.ttf ColorUniEmoji.ttf DcmColorEmoji.ttf CombinedColorEmoji.ttf NotoColorEmojiLegacy.ttf NotoColorEmojiFlags.ttf NotoColorEmoji.ttf'
  for i in $variants ; do
        if [ -f "/system/fonts/$i" ]; then
            cp $FONT_DIR/$FONT_EMOJI $FONT_DIR/$i && ui_print "  - Replacing $i"
        fi
  done
  
  #Facebook Messenger
  if [ -d "$MSG_DIR" ]; then
    ui_print "  - Replacing Messenger Emojis"
    cd $MSG_DIR
    rm -rf $EMOJI_DIR
    mkdir $EMOJI_DIR
    cd $EMOJI_DIR
    cp $MODPATH/system/fonts/$FONT_EMOJI ./FacebookEmoji.ttf
  fi
  
  #Facebook App
  if [ -d "$FB_DIR" ]; then
    ui_print "  - Replacing Facebook Emojis"
    cd $FB_DIR
    rm -rf $EMOJI_DIR
    mkdir $EMOJI_DIR
    cd $EMOJI_DIR
    cp $MODPATH/system/fonts/$FONT_EMOJI ./FacebookEmoji.ttf
  fi

  # Compat fonts
  cd "/"
  ui_print "  - Checking combat fonts"
  for i in $COMBAT_DIRS ; do
    if [ "$(ls -A $i/$COMBAT_FONT)" ]; then
      cp $MODPATH/system/fonts/$FONT_EMOJI $i/$COMBAT_FONT
    fi
  done
  
  # Verifying Android version
  android_ver=$(getprop ro.build.version.sdk)
  # If Android 12+ detected - Note: this doesn't seem to work properly
  if [ $android_ver -ge 31 ]; then
    ui_print "  - Android 12 or later detected"
    DATA_FONT_DIR="/data/fonts/files"
    if [ -d "$DATA_FONT_DIR" ] && [ "$(ls -A $DATA_FONT_DIR)" ]; then
        ui_print "  - Checking [$DATA_FONT_DIR]"
        for dir in $DATA_FONT_DIR/*/ ; do
            cd $dir
            for file in * ; do
                if [ "$file" == *ttf ] ; then
                    cp $MODPATH/system/fonts/$FONT_EMOJI $file && ui_print "  - Replacing $file"
                fi
            done
        done
    fi
    # Create /data/fonts/files if not exists
    cd "/"
    if [ ! -d "$DATA_FONT_DIR" ]; then
      ui_print "  - Creating $DATA_FONT_DIR"
      mkdir -p "$DATA_FONT_DIR/"
    fi 
    # Push font to /data/fonts/files
    ui_print "  - Pushing to $DATA_FONT_DIR"
    cp $MODPATH/system/fonts/$FONT_EMOJI $DATA_FONT_DIR/$FONT_EMOJI
  fi
  
  [[ -d /sbin/.core/mirror ]] && MIRRORPATH=/sbin/.core/mirror || unset MIRRORPATH
  FONTS=/system/etc/fonts.xml
  FONTFILES=$(sed -ne '/<family lang="und-Zsye".*>/,/<\/family>/ {s/.*<font weight="400" style="normal">\(.*\)<\/font>.*/\1/p;}' $MIRRORPATH$FONTS)
  for font in $FONTFILES
  do
    ln -s /system/fonts/NotoColorEmoji.ttf $MODPATH/system/fonts/$font
  done
}

set_permissions() {
  set_perm_recursive $MODPATH 0 0 0755 0644
  set_perm_recursive $DATA_FONT_DIR 0 0 0755 0644
  set_perm_recursive /data/data/com.facebook.katana/app_ras_blobs/FacebookEmoji.ttf 0 0 0755 700
  set_perm_recursive /data/data/com.facebook.katana/app_ras_blobs 0 0 0755 755
  set_perm_recursive /data/data/com.facebook.orca/app_ras_blobs/FacebookEmoji.ttf 0 0 0755 700

  for i in $COMBAT_DIRS ; do
    set_perm_recursive $i/$COMBAT_FONT 0 0 0755 0644
  done
}
