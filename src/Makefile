.PHONY: cmd clean test

cmd: $(wildcard ./image-syncer/pkg/client/*.go ./image-syncer/pkg/sync/*.go ./image-syncer/pkg/task/*.go ./image-syncer/pkg/utils/*.go ./image-syncer/cmd/*.go ./image-syncer/*.go)
	cd image-syncer && go build -o ../../image-syncer .

test:
	cd image-syncer && go test ./...

clean:
	rm image-syncer