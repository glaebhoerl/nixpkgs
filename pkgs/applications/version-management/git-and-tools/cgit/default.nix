{ stdenv, fetchurl, openssl, zlib, asciidoc, libxml2, libxslt
, docbook_xml_xslt, pkgconfig, luajit
, gzip, bzip2, xz
}:

stdenv.mkDerivation rec {
  name = "cgit-${version}";
  version = "0.11.2";

  src = fetchurl {
    url = "http://git.zx2c4.com/cgit/snapshot/${name}.tar.xz";
    sha256 = "0fryh56kyah7v9a8zzhbhwlyy2j116w87sxmgrn2kmwk0rvnw4if";
  };

  # cgit is tightly coupled with git and needs a git source tree to build.
  # IMPORTANT: Remember to check which git version cgit needs on every version
  # bump (look in the Makefile).
  # NOTE: as of 0.10.1, the git version is compatible from 1.9.0 to
  # 1.9.2 (see the repository history)
  gitSrc = fetchurl {
    url    = "mirror://kernel/software/scm/git/git-2.3.2.tar.xz";
    sha256 = "09gqijsjfnxlbsxbxzlvllg37bfs9f4jwa2plqsanmba09i89sqq";
  };

  buildInputs = [
    openssl zlib asciidoc libxml2 libxslt docbook_xml_xslt pkgconfig luajit
  ];

  postPatch = ''
    sed -e 's|"gzip"|"${gzip}/bin/gzip"|' \
        -e 's|"bzip2"|"${bzip2}/bin/bzip2"|' \
        -e 's|"xz"|"${xz}/bin/xz"|' \
        -i ui-snapshot.c
  '';

  # Give cgit a git source tree and pass configuration parameters (as make
  # variables).
  preBuild = ''
    mkdir -p git
    tar --strip-components=1 -xf "$gitSrc" -C git

    makeFlagsArray+=(prefix="$out" CGIT_SCRIPT_PATH="$out/cgit/")
  '';

  # Install manpage.
  postInstall = ''
    # xmllint fails:
    #make install-man

    # bypassing xmllint works:
    a2x --no-xmllint -f manpage cgitrc.5.txt
    mkdir -p "$out/share/man/man5"
    cp cgitrc.5 "$out/share/man/man5"
  '';

  meta = {
    homepage = http://git.zx2c4.com/cgit/about/;
    repositories.git = git://git.zx2c4.com/cgit;
    description = "Web frontend for git repositories";
    license = stdenv.lib.licenses.gpl2;
    platforms = stdenv.lib.platforms.linux;
    maintainers = with stdenv.lib.maintainers; [ bjornfor ];
  };
}
