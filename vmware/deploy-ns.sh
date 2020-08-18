#!/bin/sh

case $1 in
    "--set")
        case $2 in
            applycrds)
                kubectl apply -f ../yaml/objectscale-crd.yaml
            ;;
        esac
    ;;
esac

kubectl apply -f ../yaml/objectscale-manager.yaml -f ../yaml/decks.yaml -f ../yaml/kahm.yaml
