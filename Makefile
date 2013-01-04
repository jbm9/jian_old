TEMPDIR=build/
TEMPLATES=$(TEMPDIR)/header.html $(TEMPDIR)/footer.html 

TARGETS=index.html projects.html links.html missing.html log/index.html

MEDIA_build=$(wildcard build/media/*.html)
MEDIA=$(MEDIA_build:build/%=%)
MEDIA_build_IMG=$(wildcard build/media/*)
MEDIA_IMG=$(MEDIA_build_IMG:build/%=%)

LOG_build=$(wildcard build/log/*.html)
LOG=$(LOG_build:build/%=%)

UPLOADS=$(TARGETS) jian0602.css headshot.png newlogo-trans-small-mod.png newlogo_threshold.gif vgrad_6E_2E.png index.xml
EF_DEST=mirabel.epfarms.org:~/joshisanerd.com/
DH_DEST=USER@wilmington.dreamhost.com:~/joshisanerd.com/

CPP=cpp

all: $(TARGETS) media_index $(MEDIA) blog_index $(LOG) index_rss

index_rss: build/index.xml build/rss_head.xml build/rss_foot.xml
	./build_rss.sh
	cp build/index.xml .

build/log/index.html: build/mk_recent_blog.pl build/*.html build/media/*.html build/log/*.html
	./build_blog.sh

blog_index:
	./build_blog.sh
	./build_blog_rss.sh
	cp build/log/index.xml log/index.xml

log/%.html: build/log/%.html blog_index $(TEMPLATES)
	$(CPP) -traditional-cpp -I$(TEMPDIR) $< $@.tmp
	grep -v '^#' $@.tmp | grep -v '^ *$$' > $@
	rm -f $@.tmp



media/img/%: build/media/img/%
	cp $< $@

media_index: build/media/*.html
	./build_meta_media.sh

media/%.html: build/media/%.html $(TEMPLATES)
	$(CPP) -traditional-cpp -I$(TEMPDIR) $< $@.tmp
	grep -v '^#' $@.tmp | grep -v '^ *$$' > $@
	rm -f $@.tmp

log/%.html: build/log/%.html $(TEMPLATES)
	$(CPP) -traditional-cpp -I$(TEMPDIR) $< $@.tmp
	grep -v '^#' $@.tmp | grep -v '^ *$$' > $@
	rm -f $@.tmp

%.html: build/%.html $(TEMPLATES)
	$(CPP) -traditional-cpp -I$(TEMPDIR) $< $@.tmp
	grep -v '^#' $@.tmp | grep -v '^ *$$' > $@
	rm -f $@.tmp

dh_upload: dh_upload_test
	rsync --exclude .svn -v $(UPLOADS) $(DH_DEST)
	rsync --exclude .svn -rv media/ $(DH_DEST)/media/
	rsync --exclude .svn -rv log/ $(DH_DEST)/log/

dh_upload_test:
	rsync --exclude .svn -nv $(UPLOADS) $(DH_DEST)
	rsync --exclude .svn -nrv media/ $(DH_DEST)/media/

ef_upload:
	rsync --exclude .svn -v $(UPLOADS) $(EF_DEST)

upload: dh_upload

build/index.xml: ./build_recent_xml.sh build/mk_recent_xml.pl build/log/*.html build/media/*.html
	./build_recent_xml.sh

build/log/index.xml: ./build_log_recent_xml.sh build/mk_log_recent_xml.pl build/log/*.html build/media/*.html
	./build_log_recent_xml.sh
