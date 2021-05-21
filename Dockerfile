ARG BUILD_FROM
# Build the Swift executable
FROM swift:5.3 AS build

COPY . /Sources
WORKDIR /Sources
RUN swift build -c release

FROM swift:5.3-slim

ENV LANG C.UTF-8

# Copy to the image
COPY --from=build /Sources/.build/release/RoomOccupancy /
RUN chmod a+x /RoomOccupancy

# # Copy data for add-on
# COPY run.sh /
# RUN chmod a+x /run.sh

CMD [ "/RoomOccupancy" ]
