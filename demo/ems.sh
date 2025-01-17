#!/bin/sh

ProgName=$(basename $0)
Command=$1

sub_help(){
    echo "Usage: $ProgName <command> [options]\n"
    echo "Commands:"
    echo "    admin:        call the admin CLI for the given environment (corresponding to the admin-{environment} docker compose service)"
    echo "    web:          call the web CLI for the given environment (corresponding to the web-{environment} docker compose service)"
    echo "    create_users: create demo users in the given environment (corresponding to the admin-{environment} docker compose service)"
    echo "    config_push:  upload admin's configuration in the given environment (corresponding to the web-{environment} docker compose service)"
    echo "    config_pull:  download admin's configuration from the given environment (corresponding to the web-{environment} docker compose service)"
    echo ""
}

sub_admin(){
  environment=$1
  shift

  docker compose exec -u ${UID:-1000} admin-${environment} ems-demo $@
}

sub_web(){
  environment=$1
  shift

  docker compose exec -u ${UID:-1000} web-${environment} preview $@
}

sub_create_users(){
  environment=$1
  docker compose exec -u ${UID:-1000} admin-${environment} ems-demo emsco:user:create author author@example.com author
  docker compose exec -u ${UID:-1000} admin-${environment} ems-demo emsco:user:promote author ROLE_AUTHOR
  docker compose exec -u ${UID:-1000} admin-${environment} ems-demo emsco:user:promote author ROLE_COPY_PASTE
  docker compose exec -u ${UID:-1000} admin-${environment} ems-demo emsco:user:create publisher publisher@example.com publisher
  docker compose exec -u ${UID:-1000} admin-${environment} ems-demo emsco:user:promote publisher ROLE_PUBLISHER
  docker compose exec -u ${UID:-1000} admin-${environment} ems-demo emsco:user:promote publisher ROLE_COPY_PASTE
  docker compose exec -u ${UID:-1000} admin-${environment} ems-demo emsco:user:promote publisher ROLE_ALLOW_ALIGN
  docker compose exec -u ${UID:-1000} admin-${environment} ems-demo emsco:user:create webmaster webmaster@example.com webmaster
  docker compose exec -u ${UID:-1000} admin-${environment} ems-demo emsco:user:promote webmaster ROLE_WEBMASTER
  docker compose exec -u ${UID:-1000} admin-${environment} ems-demo emsco:user:promote webmaster ROLE_COPY_PASTE
  docker compose exec -u ${UID:-1000} admin-${environment} ems-demo emsco:user:promote webmaster ROLE_ALLOW_ALIGN
  docker compose exec -u ${UID:-1000} admin-${environment} ems-demo emsco:user:promote webmaster ROLE_FORM_CRM
  docker compose exec -u ${UID:-1000} admin-${environment} ems-demo emsco:user:promote webmaster ROLE_TASK_MANAGER
  docker compose exec -u ${UID:-1000} admin-${environment} ems-demo emsco:user:create demo --super-admin
  docker compose exec -u ${UID:-1000} admin-${environment} ems-demo emsco:user:promote demo ROLE_API
  docker compose exec -u ${UID:-1000} admin-${environment} ems-demo emsco:user:promote demo ROLE_COPY_PASTE
  docker compose exec -u ${UID:-1000} admin-${environment} ems-demo emsco:user:promote demo ROLE_ALLOW_ALIGN
  docker compose exec -u ${UID:-1000} admin-${environment} ems-demo emsco:user:promote demo ROLE_FORM_CRM
  docker compose exec -u ${UID:-1000} admin-${environment} ems-demo emsco:user:promote demo ROLE_TASK_MANAGER
}

sub_config_push(){
  environment=$1
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:login --username=demo

  echo "Upload assets"
  docker compose exec -u ${UID:-1000} web-${environment} preview emsch:local:folder-upload /opt/src/admin/assets

  echo "Create/Update Filters"
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:update filter dutch_stemmer
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:update filter dutch_stop
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:update filter empty_elision
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:update filter english_stemmer
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:update filter english_stop
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:update filter french_elision
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:update filter french_stemmer
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:update filter french_stop
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:update filter german_stemmer
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:update filter german_stop


  echo "Create/Update Analyzers"
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:update analyzer alpha_order
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:update analyzer dutch_for_highlighting
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:update analyzer english_for_highlighting
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:update analyzer french_for_highlighting
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:update analyzer german_for_highlighting
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:update analyzer html_strip

  echo "Create/Update Schedules"
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:update schedule check-aliases
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:update schedule clear-logs
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:update schedule publish-releases
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:update schedule remove-expired-submissions

  echo "Create/Update WYSIWYG Style Sets"
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:update wysiwyg-style-set DemoStyleSet
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:update wysiwyg-style-set RevealJS

  echo "Create/Update WYSIWYG Profiles"
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:update wysiwyg-profile Full
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:update wysiwyg-profile Light
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:update wysiwyg-profile Sample
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:update wysiwyg-profile Standard

  echo "Create/Update i18n"
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:update i18n config
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:update i18n ems.documentation.body
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:update i18n locale.fr
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:update i18n locale.nl
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:update i18n locale.de
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:update i18n locale.en
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:update i18n locales
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:update i18n asset.type.manual

  echo "Create/Update Environments"
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:update environment preview
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:update environment live

  echo "Create/Update ContentTypes"
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:update content-type label
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:update content-type route
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:update content-type template
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:update content-type page
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:update content-type structure
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:update content-type publication
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:update content-type slideshow
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:update content-type form_instance
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:update content-type asset

  echo "Create/Update QuerySearches"
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:update query-search pages
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:update query-search documents
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:update query-search forms

  echo "Create/Update Dashboards"
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:update dashboard welcome
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:update dashboard default-search

  echo "Create/Update Channels"
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:update channel preview
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:update channel live

  echo "Rebuild environments and activate content types"
  #docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:job rebuild-preview
  docker compose exec -u ${UID:-1000} admin-${environment} ems-demo ems:environment:rebuild preview
  #docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:job rebuild-live
  docker compose exec -u ${UID:-1000} admin-${environment} ems-demo ems:environment:rebuild live
  #docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:job activate-all-content-type
  docker compose exec -u ${UID:-1000} admin-${environment} ems-demo ems:contenttype:activate --all

  echo "Push templates, routes and translations"
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:local:push --force

  echo "Upload documents"
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:document:upload page
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:document:upload structure
#  docker compose exec -u ${UID:-1000} web-${environment} preview ems:document:upload publication
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:document:upload slideshow
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:document:upload form_instance
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:document:upload asset

  echo "Align live"
  docker compose exec -u ${UID:-1000} admin-${environment} ems-demo ems:environment:align preview live --force
}

sub_config_pull(){
  environment=$1
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:login

  echo "Update admin configs Filters"
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:get filter --export

  echo "Update admin configs Analyzers"
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:get analyzer --export

  echo "Update admin configs Schedules"
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:get schedule --export

  echo "Update admin configs WYSIWYG Style Sets"
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:get wysiwyg-style-set --export

  echo "Update admin configs WYSIWYG Profiles"
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:get wysiwyg-profile --export

  echo "Update admin configs i18n"
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:get i18n --export

  echo "Update admin configs Environments"
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:get environment --export

  echo "Update admin configs ContentTypes"
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:get content-type --export

  echo "Update admin configs QuerySearches"
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:get query-search --export

  echo "Update admin configs Dashboards"
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:get dashboard --export

  echo "Update admin configs Channels"
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:admin:get channel --export

  echo "Download documents"
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:document:download page
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:document:download publication
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:document:download slideshow
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:document:download structure
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:document:download form_instance
  docker compose exec -u ${UID:-1000} web-${environment} preview ems:document:download asset
}


case $Command in
    "" | "-h" | "--help")
        sub_help
        ;;
    *)
        shift
        sub_${Command} $@
        if [ $? = 127 ]; then
            echo "Error: '$Command' is not a known command." >&2
            echo "       Run '$ProgName --help' for a list of known commands." >&2
            exit 1
        fi
        ;;
esac
