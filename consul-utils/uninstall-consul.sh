# remove user and (if it's empty) group
deluser $CONSUL_USER
delgroup --only-if-empty $CONSUL_USER

# delete all files and dirs
rm -Rf "~/$CONSUL_ARCHIVE"
rm -Rf $CONSUL_PATH
rm -Rf $CONSUL_CONF_FILE
rm -Rf $CONSUL_CONF_DIR
rm -Rf $CONSUL_DATA_DIR
rm -Rf $CONSUL_LOG

