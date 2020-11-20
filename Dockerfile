#
# Copyright (c) 2020 EMC Corporation
# All Rights Reserved
#
# This software contains the intellectual property of EMC Corporation
# or is licenecho to EMC Corporation from third parties. Use of this
# software and the intellectual property contained therein is expressly
# limited to the terms and conditions of the License Agreement under which
# it is provided by or on behalf of EMC.
#

# Dockerfile for install-controller

FROM asdrepo.isus.emc.com:8099/install-controller:green

ADD   ./docs /docs
