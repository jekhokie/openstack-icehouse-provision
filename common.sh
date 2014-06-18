#!/bin/bash

for file in $(ls lib/*); do source $file; done

# common functionality installed on each and every node
