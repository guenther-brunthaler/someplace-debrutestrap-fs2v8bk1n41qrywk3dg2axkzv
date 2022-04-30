#! /bin/sh
find debian/archives -name *.deb | while IFS= read -r pf; do prf=${pf##*/} && (cd work && find -delete) && cp -- "$pf" work && (cd work && ar xo $prf && tar -xf control.*) && sed '${p; s|.*|X-Location: '"$pf"'|; p; s/.*//}' < work/control; done > plist
