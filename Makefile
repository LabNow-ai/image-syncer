.PHONY: cmd clean test

cmd: $(wildcard ./src/image-syncer/pkg/client/*.go ./src/image-syncer/pkg/sync/*.go ./src/image-syncer/pkg/task/*.go ./src/image-syncer/pkg/utils/*.go ./src/image-syncer/cmd/*.go ./src/image-syncer/*.go)
	cd src/image-syncer && go build -o ../../image-syncer .

test:
	cd src/image-syncer && go test ./...

clean: 
	rm image-syncer