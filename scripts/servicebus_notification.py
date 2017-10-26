#!/usr/bin/python

# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

# This python script sends a notification message to the specified servicebus queue

import click
import click_log
import sys

from azure.servicebus import ServiceBusService, Message

# parameter handling
@click.command()
@click.option(
    '--namespace',
    help='Service bus namespace'
)
@click.option(
    '--queue_name',
    help='Service bus queue name'
)
@click.option(
    '--shared_access_key_name',
    default="RootManageSharedAccessKey",
    help='Name of the shared access policy'
)
@click.option(
    '--shared_access_key',
    help='comma-separated list of objectIds to target for pruning'
)
@click.option(
    '--message',
    default=None,
    help='comma-separated list of objectIds to target for pruning'
)
def servicebus_notification(
        namespace,
        queue_name,
        shared_access_key_name,
        shared_access_key,
        message):

    """
    Send notification message to an existing service bus queue
    """

    servicebus = ServiceBusService(
        service_namespace=namespace,
        shared_access_key_name=shared_access_key_name,
        shared_access_key_value=shared_access_key)

    notification_message = Message(message)

    # let the exception bubble up to be handled by the caller
    servicebus.send_queue_message(queue_name, notification_message)

if __name__ == "__main__":
    servicebus_notification() # pylint: disable=no-value-for-parameter