# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sci-visualization/gnuplot/gnuplot-4.6.1-r1.ebuild,v 1.5 2013/03/07 20:35:32 ottxor Exp $

EAPI=5

inherit elisp-common eutils flag-o-matic multilib readme.gentoo toolchain-funcs wxwidgets

DESCRIPTION="Command-line driven interactive plotting program"
HOMEPAGE="http://www.gnuplot.info/"

if [[ -z ${PV%%*9999} ]]; then
	inherit autotools cvs
	ECVS_SERVER="gnuplot.cvs.sourceforge.net:/cvsroot/gnuplot"
	ECVS_MODULE="gnuplot"
	ECVS_BRANCH="branch-4-6-stable"
	ECVS_USER="anonymous"
	ECVS_CVS_OPTIONS="-dP"
	MY_P="${PN}"
	SRC_URI=""
else
	MY_P="${P/_/.}"
	SRC_URI="mirror://sourceforge/gnuplot/${MY_P}.tar.gz"
fi

LICENSE="gnuplot GPL-2 bitmap? ( free-noncomm )"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~ppc ~ppc64 ~s390 ~sparc ~x86 ~x86-fbsd ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~x64-solaris ~x86-solaris"
IUSE="aqua bitmap cairo doc emacs examples +gd ggi latex lua plotutils qt4 readline svga thin-splines wxwidgets X xemacs"

RDEPEND="
	cairo? (
		x11-libs/cairo
		x11-libs/pango )
	emacs? ( virtual/emacs )
	!emacs? ( xemacs? (
		app-editors/xemacs
		app-xemacs/xemacs-base ) )
	gd? ( media-libs/gd[png] )
	ggi? ( media-libs/libggi )
	latex? (
		virtual/latex-base
		lua? (
			dev-tex/pgf
			>=dev-texlive/texlive-latexrecommended-2008-r2 ) )
	lua? ( dev-lang/lua )
	plotutils? ( media-libs/plotutils )
	qt4? ( >=dev-qt/qtcore-4.5:4
		>=dev-qt/qtgui-4.5:4
		>=dev-qt/qtsvg-4.5:4 )
	readline? ( sys-libs/readline )
	svga? ( media-libs/svgalib )
	wxwidgets? (
		x11-libs/wxGTK:2.8[X]
		x11-libs/cairo
		x11-libs/pango
		x11-libs/gtk+:2 )
	X? ( x11-libs/libXaw )"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	doc? (
		virtual/latex-base
		dev-texlive/texlive-latexextra
		app-text/ghostscript-gpl )
	!emacs? ( xemacs? ( app-xemacs/texinfo ) )"

if [[ -z ${PV%%*9999} ]]; then
	# The live ebuild always needs an Emacs for building of gnuplot.texi
	DEPEND="${DEPEND}
	|| ( virtual/emacs app-xemacs/texinfo )"
fi

S="${WORKDIR}/${MY_P}"

GP_VERSION="${PV%.*}"
E_SITEFILE="lisp/50${PN}-gentoo.el"
TEXMF="${EPREFIX}/usr/share/texmf-site"

src_prepare() {
	if [[ -z ${PV%%*9999} ]]; then
		local dir
		for dir in config demo m4 term tutorial; do
			emake -C "$dir" -f Makefile.am.in Makefile.am
		done
		eautoreconf
	fi

	# Add special version identification as required by provision 2
	# of the gnuplot license
	sed -i -e "1s/.*/& (Gentoo revision ${PR})/" PATCHLEVEL || die

	# hacky workaround
	# Please hack the buildsystem if you like
	if use prefix && use qt4; then
		append-ldflags -Wl,-rpath,"${EPREFIX}"/usr/$(get_libdir)/qt4
	fi

	DOC_CONTENTS='Gnuplot no longer links against pdflib, see the ChangeLog
		for details. You can use the "pdfcairo" terminal for PDF output.'
	use cairo || DOC_CONTENTS+=' It is available with USE="cairo".'
	use svga && DOC_CONTENTS+='\n\nIn order to enable ordinary users to use
		SVGA console graphics, gnuplot needs to be set up as setuid root.
		Please note that this is usually considered to be a security hazard.
		As root, manually "chmod u+s /usr/bin/gnuplot".'
	use gd && DOC_CONTENTS+='\n\nFor font support in png/jpeg/gif output,
		you may have to set the GDFONTPATH and GNUPLOT_DEFAULT_GDFONT
		environment variables. See the FAQ file in /usr/share/doc/${PF}/
		for more information.'
}

src_configure() {
	if ! use latex; then
		sed -i -e '/SUBDIRS/s/LaTeX//' share/Makefile.in || die
	fi

	if use wxwidgets; then
		WX_GTK_VER="2.8"
		need-wxwidgets unicode
	fi

	tc-export CC CXX			#453174

	local emacs lispdir
	if use emacs; then
		emacs=emacs
		lispdir="${EPREFIX}${SITELISP}/${PN}"
		use xemacs \
			&& ewarn "USE flag \"xemacs\" ignored (superseded by \"emacs\")"
	elif use xemacs; then
		emacs=xemacs
		lispdir="${EPREFIX}/usr/lib/xemacs/site-packages/${PN}"
	else
		emacs=no
		lispdir=""
		if [[ -z ${PV%%*9999} ]]; then
			# Live ebuild needs an Emacs to build gnuplot.texi
			if has_version virtual/emacs; then emacs=emacs
			elif has_version app-xemacs/texinfo; then emacs=xemacs; fi
			# for emacs != no gnuplot will install lisp files in 
			# ${lispdir}/ which will / for emtpy lispdir
			lispdir="${T}"
		fi
	fi

	econf \
		--without-pdf \
		--with-texdir="${TEXMF}/tex/latex/${PN}" \
		--with-readline=$(usex readline gnu builtin) \
		--with-lispdir="${lispdir}" \
		--with$([[ -z ${lispdir} ]] && echo out)-lisp-files \
		$(use_with bitmap bitmap-terminals) \
		$(use_with cairo) \
		$(use_with doc tutorial) \
		$(use_with gd) \
		"$(use_with ggi ggi "${EPREFIX}/usr/$(get_libdir)")" \
		"$(use_with ggi xmi "${EPREFIX}/usr/$(get_libdir)")" \
		$(use_with lua) \
		"$(use_with plotutils plot "${EPREFIX}/usr/$(get_libdir)")" \
		$(use_with svga linux-vga) \
		$(use_with X x) \
		--enable-stats \
		$(use_enable qt4 qt) \
		$(use_enable thin-splines) \
		$(use_enable wxwidgets) \
		DIST_CONTACT="http://bugs.gentoo.org/" \
		EMACS="${emacs}"
}

src_compile() {
	# Prevent access violations, see bug 201871
	VARTEXFONTS="${T}/fonts"

	# We believe that the following line is no longer needed.
	# In case of problems file a bug report at bugs.gentoo.org.
	#addwrite /dev/svga:/dev/mouse:/dev/tts/0

	emake all info

	if use doc; then
		# Avoid sandbox violation in epstopdf/ghostscript
		addpredict /var/cache/fontconfig
		emake -C docs pdf
		emake -C tutorial pdf
		use emacs || use xemacs && emake -C lisp pdf
	fi
}

src_install () {
	emake DESTDIR="${D}" install

	if use emacs; then
		# Gentoo Emacs site-lisp configuration
		echo "(add-to-list 'load-path \"@SITELISP@\")" > ${E_SITEFILE}
		sed '/^;; move/,+3 d' lisp/dotemacs >> ${E_SITEFILE} || die
		elisp-site-file-install ${E_SITEFILE} || die
	fi

	dodoc BUGS ChangeLog NEWS PGPKEYS PORTING README*
	newdoc term/PostScript/README README-ps
	newdoc term/js/README README-js
	use lua && newdoc term/lua/README README-lua
	readme.gentoo_create_doc

	if use examples; then
		# Demo files
		insinto /usr/share/${PN}/${GP_VERSION}
		doins -r demo
		rm -f "${ED}"/usr/share/${PN}/${GP_VERSION}/demo/Makefile*
		rm -f "${ED}"/usr/share/${PN}/${GP_VERSION}/demo/binary*
	fi

	if use doc; then
		# Manual, tutorial, FAQ
		dodoc docs/gnuplot.pdf tutorial/{tutorial.dvi,tutorial.pdf} FAQ.pdf
		# Documentation for making PostScript files
		docinto psdoc
		dodoc docs/psdoc/{*.doc,*.tex,*.ps,*.gpi,README}
	fi

	if use emacs || use xemacs; then
		docinto emacs
		dodoc lisp/ChangeLog lisp/README
		use doc && dodoc lisp/gpelcard.pdf
	fi
}

src_test() {
	GNUTERM="unknown" default_src_test
}

pkg_postinst() {
	use emacs && elisp-site-regen
	use latex && texmf-update
	readme.gentoo_print_elog
}

pkg_postrm() {
	use emacs && elisp-site-regen
	use latex && texmf-update
}
