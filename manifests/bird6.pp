class ffnord::bird6 () {
  package { 
    'bird6':
      ensure => installed;
  }
 
  file {
    '/etc/bird/bird6.conf.d/':
      ensure => directory,
      mode => "0755",
      owner => root,
      group => root,
      require => File['/etc/bird/bird6.conf'];
  }

  service { 
    'bird6': 
      ensure => running,
      enable => true,
      require => Package['bird6'];
  }

  file { 
    '/etc/bird/':
      ensure => directory,
      mode => '0755'
  }

  file { '/etc/bird/bird6.conf':
    ensure => file,
    mode => "0644",
    content => template("ffnord/etc/bird/bird6.conf.erb"),
    notify => Service['bird6'],
    require => [Package['bird6'],File['/etc/bird/']]
  } 
}

define ffnord::bird6::mesh (
  $mesh_code,

  $mesh_ipv4_address,
  $mesh_ipv6_address,
  $mesh_peerings, # YAML data file for local peerings

  $icvpn_as,

  $site_ipv6_prefix,
) {

  include ffnord::bird6

  file { "/etc/bird/bird6.conf.d/${mesh_code}.conf":
    mode => "0644",
    content => template("ffnord/etc/bird/bird6.interface.conf.erb"),
    require => [File['/etc/bird/bird6.conf.d/'],Package['bird6']],
    notify  => Service['bird6'];
  }
}

define ffnord::bird6::icvpn (
  $icvpn_as,
  $icvpn_ipv4_address,
  $icvpn_ipv6_address,
  $icvpn_peerings = [],

  $tinc_keyfile,
  ){

  include ffnord::bird6

  $icvpn_name = $name

  class { 'ffnord::tinc': 
    tinc_name    => $icvpn_name,
    tinc_keyfile => $tinc_keyfile,

    icvpn_ipv4_address => $icvpn_ipv4_address,
    icvpn_ipv6_address => $icvpn_ipv6_address,

    icvpn_peers  => $icvpn_peerings;
  }

  # Process meta data from tinc directory
  file { "/etc/bird/bird6.conf.d/bird6.icvpn-peers.conf":
    mode => "0644",
    content => template("ffnord/etc/bird/bird6.icvpn-peers.conf.erb"),
    require => [File['/etc/bird/bird6.conf.d/'],Package['bird6'],Class['ffnord::tinc']],
    notify  => Service['bird6'];
  } 
}