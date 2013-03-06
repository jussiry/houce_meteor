

## Install

Unfortunately Meteor package API is not yet ready, so we have to clone and link the package manually.

    git clone https://github.com/jussiry/houce_meteor.git
    ln -s /dir/where/you/made/clone/command/houce_meteor/js /meteor/installation/dir/packages/houce

In OS X Meteor installation dir is '/usr/local/meteor' and in Ubuntu '/usr/lib/meteor'. Notice that you have to write the full dir, e.g. './houce_meteor/js' won't work.


## Developing package

If you want to develope this package further, run 'cake compile', which will look for changes in /coffee folder and compile them into /js folder. Since /js folder is linked to Meteor packages, file change will cause automatic restart of server and reload of the webapp.


## Documentation

TODO. For now you can look into non-meteor version of houce to get some idea: https://github.com/jussiry/houce